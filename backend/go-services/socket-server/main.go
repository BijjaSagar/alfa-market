package main

import (
	"context"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for MVP
	},
}

type Server struct {
	clients   map[*websocket.Conn]bool
	broadcast chan []byte
	mutex     sync.Mutex
}

func newServer() *Server {
	return &Server{
		clients:   make(map[*websocket.Conn]bool),
		broadcast: make(chan []byte),
	}
}

func (s *Server) handleConnections(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer ws.Close()

	s.mutex.Lock()
	s.clients[ws] = true
	s.mutex.Unlock()

	log.Println("New Client Connected")

	for {
		_, _, err := ws.ReadMessage()
		if err != nil {
			s.mutex.Lock()
			delete(s.clients, ws)
			s.mutex.Unlock()
			break
		}
	}
}

func (s *Server) handleMessages() {
	for {
		msg := <-s.broadcast
		s.mutex.Lock()
		for client := range s.clients {
			err := client.WriteMessage(websocket.TextMessage, msg)
			if err != nil {
				log.Printf("Websocket error: %v", err)
				client.Close()
				delete(s.clients, client)
			}
		}
		s.mutex.Unlock()
	}
}

func main() {
	// Redis Connection
	rdb := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})
	ctx := context.Background()

	server := newServer()
	go server.handleMessages()

	// Subscribe to Redis Channels
	pubsub := rdb.Subscribe(ctx, "market_ticks", "order_updates")
	defer pubsub.Close()

	// Redis Listener Routine
	go func() {
		ch := pubsub.Channel()
		for msg := range ch {
			// In a real app, we would filter order updates by user_id here
			// For MVP, we broadcast everything
			server.broadcast <- []byte(msg.Payload)
		}
	}()

	http.HandleFunc("/stream", server.handleConnections)

	log.Println("Socket Server started on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
