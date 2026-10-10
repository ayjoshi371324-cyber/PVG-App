import random
import time
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.auth import get_current_user, require_role
from app.database import get_db_connection
from app.websockets import ws_manager

router = APIRouter(prefix="/trips", tags=["Trips"])


class StartTripSchema(BaseModel):
    vehicle_id: str
    booking_id: Optional[str] = None
    total_shared_km: float = 12.0
    fare: float = 140.0


class VerifyOtpSchema(BaseModel):
    otp: str


@router.post("/start", status_code=status.HTTP_201_CREATED)
async def start_trip(data: StartTripSchema, current_user: dict = Depends(get_current_user)):
    trip_id = f"trip-{int(time.time() * 1000)}"
    # 4-digit pickup verification OTP
    otp_code = f"{random.randint(1000, 9999)}"

    conn = get_db_connection()
    conn.execute("""
    INSERT INTO trips (id, vehicle_id, driver_id, status, total_shared_km, fare, otp_code, otp_verified)
    VALUES (?, ?, ?, 'active', ?, ?, ?, 0)
    """, (trip_id, data.vehicle_id, current_user["id"], data.total_shared_km, data.fare, otp_code))

    # Update vehicle status to inPool
    conn.execute("""
    UPDATE vehicles
    SET status = 'inPool', current_occupancy = 2, onboard_seats = 2, reserved_seats = 0, held_seats = 0
    WHERE id = ?
    """, (data.vehicle_id,))

    if data.booking_id:
        conn.execute("UPDATE bookings SET status = 'in_trip' WHERE id = ?", (data.booking_id,))

    conn.commit()
    conn.close()

    # Broadcast seat and route update
    await ws_manager.broadcast_seat_update(data.vehicle_id, onboard=2, reserved=0, held=0, free=2)

    return {
        "trip_id": trip_id,
        "vehicle_id": data.vehicle_id,
        "otp": otp_code,
        "status": "active",
        "total_shared_km": data.total_shared_km,
        "fare": data.fare,
    }


@router.get("/{trip_id}")
def get_trip(trip_id: str):
    conn = get_db_connection()
    r = conn.execute("SELECT * FROM trips WHERE id = ?", (trip_id,)).fetchone()
    conn.close()

    if not r:
        raise HTTPException(status_code=404, detail="Trip not found")

    return {
        "id": r["id"],
        "vehicle_id": r["vehicle_id"],
        "driver_id": r["driver_id"],
        "status": r["status"],
        "total_shared_km": r["total_shared_km"],
        "fare": r["fare"],
        "otp_verified": bool(r["otp_verified"]),
    }


@router.post("/{trip_id}/verify-otp")
async def verify_otp(trip_id: str, data: VerifyOtpSchema):
    conn = get_db_connection()
    trip = conn.execute("SELECT * FROM trips WHERE id = ?", (trip_id,)).fetchone()
    if not trip:
        conn.close()
        raise HTTPException(status_code=404, detail="Trip not found")

    # In demo mode, accept correct OTP or '4821'
    if data.otp == trip["otp_code"] or data.otp == "4821":
        conn.execute("UPDATE trips SET otp_verified = 1 WHERE id = ?", (trip_id,))
        conn.commit()
        conn.close()
        return {"status": "verified", "message": "Pickup OTP verified successfully. Boarding confirmed."}
    else:
        conn.close()
        raise HTTPException(status_code=400, detail="Invalid OTP code")


@router.post("/{trip_id}/complete")
async def complete_trip(trip_id: str):
    conn = get_db_connection()
    trip = conn.execute("SELECT * FROM trips WHERE id = ?", (trip_id,)).fetchone()
    if not trip:
        conn.close()
        raise HTTPException(status_code=404, detail="Trip not found")

    conn.execute("UPDATE trips SET status = 'completed' WHERE id = ?", (trip_id,))
    conn.execute("""
    UPDATE vehicles
    SET status = 'idle', current_occupancy = 0, onboard_seats = 0, reserved_seats = 0, held_seats = 0
    WHERE id = ?
    """, (trip["vehicle_id"],))
    conn.commit()
    conn.close()

    await ws_manager.broadcast_seat_update(trip["vehicle_id"], onboard=0, reserved=0, held=0, free=4)

    return {"status": "completed", "trip_id": trip_id}
