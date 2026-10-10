from typing import List, Optional
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from app.database import get_db_connection
from app.websockets import ws_manager

router = APIRouter(prefix="/vehicles", tags=["Vehicles & Fleet"])


class FleetVehicleSchema(BaseModel):
    id: str
    name: str
    license_plate: str
    status: str
    latitude: float
    longitude: float
    current_occupancy: int
    max_capacity: int
    battery_percentage: int
    assigned_route_name: Optional[str] = None
    onboard_seats: int
    reserved_seats: int
    held_seats: int
    free_seats: int


class PositionUpdateSchema(BaseModel):
    latitude: float
    longitude: float


class SeatUpdateSchema(BaseModel):
    onboard_seats: int
    reserved_seats: int
    held_seats: int


@router.get("", response_model=List[FleetVehicleSchema])
def list_vehicles():
    conn = get_db_connection()
    rows = conn.execute("SELECT * FROM vehicles").fetchall()
    conn.close()

    result = []
    for r in rows:
        onboard = r["onboard_seats"]
        reserved = r["reserved_seats"]
        held = r["held_seats"]
        max_cap = r["max_capacity"]
        free = max(0, max_cap - onboard - reserved - held)

        result.append(
            FleetVehicleSchema(
                id=r["id"],
                name=r["name"],
                license_plate=r["license_plate"],
                status=r["status"],
                latitude=r["latitude"],
                longitude=r["longitude"],
                current_occupancy=r["current_occupancy"],
                max_capacity=max_cap,
                battery_percentage=r["battery_percentage"],
                assigned_route_name=r["assigned_route_name"],
                onboard_seats=onboard,
                reserved_seats=reserved,
                held_seats=held,
                free_seats=free,
            )
        )
    return result


@router.get("/{vehicle_id}", response_model=FleetVehicleSchema)
def get_vehicle(vehicle_id: str):
    conn = get_db_connection()
    r = conn.execute("SELECT * FROM vehicles WHERE id = ?", (vehicle_id,)).fetchone()
    conn.close()

    if not r:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    onboard = r["onboard_seats"]
    reserved = r["reserved_seats"]
    held = r["held_seats"]
    max_cap = r["max_capacity"]
    free = max(0, max_cap - onboard - reserved - held)

    return FleetVehicleSchema(
        id=r["id"],
        name=r["name"],
        license_plate=r["license_plate"],
        status=r["status"],
        latitude=r["latitude"],
        longitude=r["longitude"],
        current_occupancy=r["current_occupancy"],
        max_capacity=max_cap,
        battery_percentage=r["battery_percentage"],
        assigned_route_name=r["assigned_route_name"],
        onboard_seats=onboard,
        reserved_seats=reserved,
        held_seats=held,
        free_seats=free,
    )


@router.patch("/{vehicle_id}/position")
async def update_vehicle_position(vehicle_id: str, data: PositionUpdateSchema):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "UPDATE vehicles SET latitude = ?, longitude = ? WHERE id = ?",
        (data.latitude, data.longitude, vehicle_id),
    )
    if cur.rowcount == 0:
        conn.close()
        raise HTTPException(status_code=404, detail="Vehicle not found")
    conn.commit()
    conn.close()

    # Broadcast real-time position via WebSocket
    await ws_manager.broadcast_vehicle_position(vehicle_id, data.latitude, data.longitude)

    return {"status": "success", "vehicle_id": vehicle_id}
