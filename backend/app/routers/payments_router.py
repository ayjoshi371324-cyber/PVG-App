import time
from typing import Optional
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from app.database import get_db_connection
from app.websockets import ws_manager

router = APIRouter(prefix="/payments", tags=["Payments"])


class CreateOrderSchema(BaseModel):
    booking_id: str
    amount_rupees: float


class VerifyPaymentSchema(BaseModel):
    order_id: str
    payment_id: str
    signature: Optional[str] = "simulated_valid_signature"


@router.post("/order", status_code=status.HTTP_201_CREATED)
def create_payment_order(data: CreateOrderSchema):
    order_id = f"order_{int(time.time() * 1000)}"
    amount_paise = int(data.amount_rupees * 100)

    conn = get_db_connection()
    conn.execute("""
    INSERT INTO payments (id, booking_id, order_id, amount_paise, status)
    VALUES (?, ?, ?, ?, 'created')
    """, (f"pay-{int(time.time() * 1000)}", data.booking_id, order_id, amount_paise))
    conn.commit()
    conn.close()

    return {
        "order_id": order_id,
        "amount_paise": amount_paise,
        "amount_rupees": data.amount_rupees,
        "currency": "INR",
        "key_id": "rzp_test_RidePoolPune2026",
    }


@router.post("/verify")
async def verify_payment(data: VerifyPaymentSchema):
    conn = get_db_connection()
    pay = conn.execute("SELECT * FROM payments WHERE order_id = ?", (data.order_id,)).fetchone()
    if not pay:
        conn.close()
        raise HTTPException(status_code=404, detail="Order not found")

    conn.execute("""
    UPDATE payments
    SET status = 'paid', payment_id = ?, payment_method = 'upi'
    WHERE order_id = ?
    """, (data.payment_id, data.order_id))
    conn.commit()
    conn.close()

    # Broadcast payment status to Flutter app
    await ws_manager.broadcast_payment_status(pay["booking_id"], "paid")

    return {
        "status": "success",
        "order_id": data.order_id,
        "payment_id": data.payment_id,
        "verified": True,
    }


@router.get("/receipt/{booking_id}")
def get_receipt(booking_id: str):
    conn = get_db_connection()
    bkg = conn.execute("SELECT * FROM bookings WHERE id = ?", (booking_id,)).fetchone()
    pay = conn.execute("SELECT * FROM payments WHERE booking_id = ?", (booking_id,)).fetchone()
    conn.close()

    fare_rupees = bkg["fare"] if bkg else 98.40
    paid = (pay and pay["status"] == "paid")

    return {
        "booking_id": booking_id,
        "passenger_name": bkg["passenger_name"] if bkg else "Pooja Sharma",
        "fare_rupees": fare_rupees,
        "amount_paise": int(fare_rupees * 100),
        "solo_fare_rupees": 140.0,
        "savings_rupees": max(0.0, 140.0 - fare_rupees),
        "co2_saved_grams": 480,
        "driver_name": "Santosh Tambe",
        "driver_payout_rupees": round(fare_rupees * 0.85, 2),
        "status": "paid" if paid else "completed",
    }
