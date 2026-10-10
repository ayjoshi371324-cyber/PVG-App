from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_websocket_connection_and_heartbeat():
    with client.websocket_connect("/ws") as websocket:
        websocket.send_text("ping")
        data = websocket.receive_text()
        assert "ack" in data
