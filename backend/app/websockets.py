import json
from typing import Any, Dict, List
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, event_name: str, data: Dict[str, Any]):
        message = json.dumps({"event": event_name, "data": data})
        stale_connections = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                stale_connections.append(connection)

        for stale in stale_connections:
            self.disconnect(stale)

    async def broadcast_vehicle_position(self, vehicle_id: str, lat: float, lng: float):
        await self.broadcast("vehicle_position", {
            "vehicle_id": vehicle_id,
            "latitude": lat,
            "longitude": lng,
        })

    async def broadcast_route_updated(self, route_id: str, stops: List[Dict[str, Any]]):
        await self.broadcast("route_updated", {
            "route_id": route_id,
            "stops": stops,
        })

    async def broadcast_seat_update(
        self,
        vehicle_id: str,
        onboard: int,
        reserved: int,
        held: int,
        free: int,
    ):
        await self.broadcast("seat_update", {
            "vehicle_id": vehicle_id,
            "onboard_seats": onboard,
            "reserved_seats": reserved,
            "held_seats": held,
            "free_seats": free,
        })

    async def broadcast_consent_request(
        self,
        trip_id: str,
        booking_id: str,
        new_passenger_name: str,
        detour_percent: float,
    ):
        await self.broadcast("consent_request", {
            "trip_id": trip_id,
            "booking_id": booking_id,
            "new_passenger_name": new_passenger_name,
            "detour_percent": detour_percent,
        })

    async def broadcast_payment_status(self, booking_id: str, payment_status: str):
        await self.broadcast("payment_status", {
            "booking_id": booking_id,
            "payment_status": payment_status,
        })


ws_manager = ConnectionManager()
