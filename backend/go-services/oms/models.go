package main

import "time"

type Order struct {
	ID        string    `json:"id"`
	Symbol    string    `json:"symbol"`
	Side      string    `json:"side"` // BUY or SELL
	Type      string    `json:"type"` // MARKET or LIMIT
	Quantity  int       `json:"quantity"`
	Price     float64   `json:"price"`
	Status    string    `json:"status"` // PENDING, FILLED, REJECTED
	CreatedAt time.Time `json:"created_at"`
}

type OrderRequest struct {
	Symbol   string  `json:"symbol"`
	Side     string  `json:"side"`
	Type     string  `json:"type"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}
