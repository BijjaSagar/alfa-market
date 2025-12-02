package main

import (
	"encoding/json"
	"log"
	"math"
	"math/rand"
	"net/http"
	"time"

	"github.com/redis/go-redis/v9"
	"golang.org/x/net/context"
)

// Tick represents a market tick
type Tick struct {
	Symbol    string  `json:"symbol"`
	Price     float64 `json:"price"`
	Volume    int     `json:"volume"`
	Timestamp int64   `json:"timestamp"`
}

var ctx = context.Background()

// Candle represents OHLC data
type Candle struct {
	Time   int64   `json:"time"`
	Open   float64 `json:"open"`
	High   float64 `json:"high"`
	Low    float64 `json:"low"`
	Close  float64 `json:"close"`
	Volume float64 `json:"volume"`
}

func generateCandles(symbol string) []Candle {
	var candles []Candle
	now := time.Now()
	price := 2500.0

	// Generate 100 candles (1 minute interval)
	for i := 100; i > 0; i-- {
		t := now.Add(time.Duration(-i) * time.Minute).Unix()
		open := price
		change := (rand.Float64() - 0.5) * 10
		closePrice := open + change
		high := math.Max(open, closePrice) + rand.Float64()*2
		low := math.Min(open, closePrice) - rand.Float64()*2

		candles = append(candles, Candle{
			Time:   t,
			Open:   open,
			High:   high,
			Low:    low,
			Close:  closePrice,
			Volume: rand.Float64() * 1000,
		})
		price = closePrice
	}
	return candles
}

func candlesHandler(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		http.Error(w, "Symbol required", http.StatusBadRequest)
		return
	}

	candles := generateCandles(symbol)
	w.Header().Set("Content-Type", "application/json")
	// Allow CORS for mobile/web dev
	w.Header().Set("Access-Control-Allow-Origin", "*")
	json.NewEncoder(w).Encode(candles)
}

func main() {
	// Connect to Redis
	rdb := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})

	// Start HTTP Server for Candles
	go func() {
		http.HandleFunc("/candles", candlesHandler)
		log.Println("Market Data HTTP Server started on :8081")
		if err := http.ListenAndServe(":8081", nil); err != nil {
			log.Fatal(err)
		}
	}()

	// Mock Data Generator
	symbols := []string{"RELIANCE", "TCS", "INFY", "HDFCBANK", "ICICIBANK"}

	log.Println("Starting Market Data Publisher...")

	for {
		for _, sym := range symbols {
			// Generate random price movement
			price := 2500.0 + (rand.Float64() * 10.0)

			tick := Tick{
				Symbol:    sym,
				Price:     price,
				Volume:    rand.Intn(100),
				Timestamp: time.Now().UnixMilli(),
			}

			payload, _ := json.Marshal(tick)

			// Publish to Redis
			err := rdb.Publish(ctx, "market_ticks", payload).Err()
			if err != nil {
				log.Printf("Error publishing tick: %v", err)
			}
		}
		time.Sleep(100 * time.Millisecond) // Simulate 10 ticks/sec per symbol
	}
}
