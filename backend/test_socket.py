import asyncio
import websockets
import json

async def test_socket():
    uri = "ws://localhost:8080/stream"
    async with websockets.connect(uri) as websocket:
        print("Connected to WebSocket")
        while True:
            message = await websocket.recv()
            data = json.loads(message)
            print(f"Received: {data['symbol']} - {data['price']:.2f}")
            break # Receive one message and exit for test

if __name__ == "__main__":
    asyncio.run(test_socket())
