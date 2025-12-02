package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

var (
	db  *sql.DB
	rdb *redis.Client
	ctx = context.Background()
)

func initDB() {
	var err error
	connStr := "postgres://alfa_user:alfa_password@localhost:5434/alfa_db?sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	// Create table if not exists
	query := `
	CREATE TABLE IF NOT EXISTS orders (
		id UUID PRIMARY KEY,
		symbol TEXT NOT NULL,
		side TEXT NOT NULL,
		type TEXT NOT NULL,
		quantity INT NOT NULL,
		price DECIMAL NOT NULL,
		status TEXT NOT NULL,
		created_at TIMESTAMP NOT NULL
	)`
	_, err = db.Exec(query)
	if err != nil {
		log.Fatal(err)
	}
}

func initRedis() {
	rdb = redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})
}

func placeOrderHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Create Order
	order := Order{
		ID:        uuid.New().String(),
		Symbol:    req.Symbol,
		Side:      req.Side,
		Type:      req.Type,
		Quantity:  req.Quantity,
		Price:     req.Price,
		Status:    "PENDING",
		CreatedAt: time.Now(),
	}

	// Save to DB
	_, err := db.Exec("INSERT INTO orders (id, symbol, side, type, quantity, price, status, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
		order.ID, order.Symbol, order.Side, order.Type, order.Quantity, order.Price, order.Status, order.CreatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Publish Update
	publishUpdate(order)

	// Simulate Execution (Async)
	go simulateExecution(order)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(order)
}

func simulateExecution(order Order) {
	time.Sleep(2 * time.Second) // Simulate network/exchange latency

	// Update Status to FILLED
	order.Status = "FILLED"
	_, err := db.Exec("UPDATE orders SET status = $1 WHERE id = $2", order.Status, order.ID)
	if err != nil {
		log.Printf("Error updating order: %v", err)
		return
	}

	publishUpdate(order)
}

func publishUpdate(order Order) {
	payload, _ := json.Marshal(order)
	rdb.Publish(ctx, "order_updates", payload)
}

func main() {
	initDB()
	initRedis()

	http.HandleFunc("/orders", placeOrderHandler)

	log.Println("OMS Service started on :8082")
	if err := http.ListenAndServe(":8082", nil); err != nil {
		log.Fatal(err)
	}
}
