import time
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.auth import get_current_user
from app.database import get_db_connection
from app.websockets import ws_manager

router = APIRouter(prefix="/bookings", tags=["Bookings"])


class CreateBookingSchema(BaseModel):
    passenger_name: str
    pickup_name: str
    pickup_lat: float
    pickup_lng: float
    dropoff_name: str
    dropoff_lat: float
    dropoff_lng: float
    party_size: int = 1
    tier: str = "car"
    fare: float = 0.0


class BookingSchema(BaseModel):
    id: str
    user_id: str
    passenger_name: str
    pickup_name: str
    pickup_lat: float
    pickup_lng: float
    dropoff_name: str
    dropoff_lat: float
    dropoff_lng: float
    party_size: int
    tier: str
    status: str
    fare: float


@router.post("", response_model=BookingSchema, status_code=status.HTTP_201_CREATED)
async def create_booking(
    data: CreateBookingSchema,
    current_user: dict = Depends(get_current_user),
):
    booking_id = f"bkg-{int(time.time() * 1000)}"
    conn = get_db_connection()
    conn.execute("""
    INSERT INTO bookings (id, user_id, passenger_name, pickup_name, pickup_lat, pickup_lng, dropoff_name, dropoff_lat, dropoff_lng, party_size, tier, status, fare)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'intake_queued', ?)
    """, (
        booking_id,
        current_user["id"],
        data.passenger_name,
        data.pickup_name,
        data.pickup_lat,
        data.pickup_lng,
        data.dropoff_name,
        data.dropoff_lat,
        data.dropoff_lng,
        data.party_size,
        data.tier,
        data.fare,
    ))
    conn.commit()
    conn.close()

    return BookingSchema(
        id=booking_id,
        user_id=current_user["id"],
        passenger_name=data.passenger_name,
        pickup_name=data.pickup_name,
        pickup_lat=data.pickup_lat,
        pickup_lng=data.pickup_lng,
        dropoff_name=data.dropoff_name,
        dropoff_lat=data.dropoff_lat,
        dropoff_lng=data.dropoff_lng,
        party_size=data.party_size,
        tier=data.tier,
        status="intake_queued",
        fare=data.fare,
    )


@router.get("", response_model=List[BookingSchema])
def list_bookings(current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    if current_user["role"] == "ops":
        rows = conn.execute("SELECT * FROM bookings ORDER BY created_at DESC").fetchall()
    else:
        rows = conn.execute("SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC", (current_user["id"],)).fetchall()
    conn.close()

    return [
        BookingSchema(
            id=r["id"],
            user_id=r["user_id"],
            passenger_name=r["passenger_name"],
            pickup_name=r["pickup_name"],
            pickup_lat=r["pickup_lat"],
            pickup_lng=r["pickup_lng"],
            dropoff_name=r["dropoff_name"],
            dropoff_lat=r["dropoff_lat"],
            dropoff_lng=r["dropoff_lng"],
            party_size=r["party_size"],
            tier=r["tier"],
            status=r["status"],
            fare=r["fare"],
        )
        for r in rows
    ]


@router.get("/{booking_id}", response_model=BookingSchema)
def get_booking(booking_id: str, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    r = conn.execute("SELECT * FROM bookings WHERE id = ?", (booking_id,)).fetchone()
    conn.close()

    if not r:
        raise HTTPException(status_code=404, detail="Booking not found")

    if current_user["role"] != "ops" and r["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Access denied")

    return BookingSchema(
        id=r["id"],
        user_id=r["user_id"],
        passenger_name=r["passenger_name"],
        pickup_name=r["pickup_name"],
        pickup_lat=r["pickup_lat"],
        pickup_lng=r["pickup_lng"],
        dropoff_name=r["dropoff_name"],
        dropoff_lat=r["dropoff_lat"],
        dropoff_lng=r["dropoff_lng"],
        party_size=r["party_size"],
        tier=r["tier"],
        status=r["status"],
        fare=r["fare"],
    )
