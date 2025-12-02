import json
import redis
import pandas as pd
import requests
import asyncio
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from uuid import uuid4
from contextlib import asynccontextmanager

# Configuration
REDIS_HOST = 'localhost'
REDIS_PORT = 6379
OMS_URL = 'http://localhost:8082/orders'
SYMBOLS = ["RELIANCE", "TCS", "INFY", "HDFCBANK", "ICICIBANK"]

# Data Models
class StrategyConfig(BaseModel):
    symbol: str
    fast_period: int
    slow_period: int
    quantity: int

class Strategy(StrategyConfig):
    id: str
    active: bool
    position: int = 0 # 0: Flat, 1: Long, -1: Short

# State
tick_data = {sym: [] for sym in SYMBOLS}
strategies: List[Strategy] = []
r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# Helper Functions
def get_sma(data, window):
    if len(data) < window:
        return None
    return sum(data[-window:]) / window

def place_order(symbol, side, qty, price):
    try:
        payload = {
            "symbol": symbol,
            "side": side,
            "type": "MARKET",
            "quantity": qty,
            "price": price
        }
        response = requests.post(OMS_URL, json=payload)
        if response.status_code == 200:
            print(f"✅ ORDER PLACED: {side} {qty} {symbol} @ {price:.2f}")
        else:
            print(f"❌ ORDER FAILED: {response.text}")
    except Exception as e:
        print(f"❌ CONNECTION ERROR: {e}")

def process_tick(tick):
    symbol = tick['symbol']
    price = tick['price']
    
    # Update History
    history = tick_data.get(symbol, [])
    history.append(price)
    if len(history) > 200: # Keep enough for max slow period
        history.pop(0)
    tick_data[symbol] = history

    # Evaluate Strategies
    for strategy in strategies:
        if not strategy.active or strategy.symbol != symbol:
            continue

        sma_fast = get_sma(history, strategy.fast_period)
        sma_slow = get_sma(history, strategy.slow_period)

        if sma_fast is None or sma_slow is None:
            continue

        # Trading Logic (Simple Crossover)
        # Golden Cross -> BUY
        if sma_fast > sma_slow and strategy.position <= 0:
            print(f"📈 SIGNAL ({strategy.id}): BUY {symbol}")
            place_order(symbol, "BUY", strategy.quantity, price)
            strategy.position = 1
            
        # Death Cross -> SELL
        elif sma_fast < sma_slow and strategy.position >= 0:
            print(f"📉 SIGNAL ({strategy.id}): SELL {symbol}")
            place_order(symbol, "SELL", strategy.quantity, price)
            strategy.position = -1

async def market_data_listener():
    print("🎧 Starting Redis Listener...")
    pubsub = r.pubsub()
    pubsub.subscribe('market_ticks')

    async for message in pubsub.listen():
        if message['type'] == 'message':
            try:
                tick = json.loads(message['data'])
                process_tick(tick)
            except Exception as e:
                print(f"Error processing tick: {e}")
        await asyncio.sleep(0.01) # Yield control

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    task = asyncio.create_task(market_data_listener())
    yield
    # Shutdown
    task.cancel()

app = FastAPI(lifespan=lifespan)

# API Endpoints
@app.post("/strategies", response_model=Strategy)
def create_strategy(config: StrategyConfig):
    strategy = Strategy(
        id=str(uuid4()),
        active=True,
        **config.dict()
    )
    strategies.append(strategy)
    print(f"✨ New Strategy Created: {strategy.symbol} ({strategy.fast_period}/{strategy.slow_period})")
    return strategy

@app.get("/strategies", response_model=List[Strategy])
def list_strategies():
    return strategies

@app.delete("/strategies/{strategy_id}")
def delete_strategy(strategy_id: str):
    global strategies
    strategies = [s for s in strategies if s.id != strategy_id]
    return {"status": "deleted"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
