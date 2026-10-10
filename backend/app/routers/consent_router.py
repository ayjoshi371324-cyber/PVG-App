import time
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from app.database import get_db_connection
from app.websockets import ws_manager

router = APIRouter(prefix="/consent", tags=["Dynamic Consent"])


class CreateConsentSchema(BaseModel):
    trip_id: str
    booking_id: str
    new_passenger_name: str
    new_detour_percent: float


class VoteConsentSchema(BaseModel):
    approved: bool


@router.post("/request", status_code=status.HTTP_201_CREATED)
async def request_consent(data: CreateConsentSchema):
    consent_id = f"cst-{int(time.time() * 1000)}"
    conn = get_db_connection()
    conn.execute("""
    INSERT INTO consent_requests (id, trip_id, booking_id, new_passenger_name, new_detour_percent, status)
    VALUES (?, ?, ?, ?, ?, 'pending')
    """, (consent_id, data.trip_id, data.booking_id, data.new_passenger_name, data.new_detour_percent))
    conn.commit()
    conn.close()

    # Broadcast via WebSocket to riders
    await ws_manager.broadcast_consent_request(
        trip_id=data.trip_id,
        booking_id=data.booking_id,
        new_passenger_name=data.new_passenger_name,
        detour_percent=data.new_detour_percent,
    )

    return {
        "consent_id": consent_id,
        "trip_id": data.trip_id,
        "status": "pending",
        "new_detour_percent": data.new_detour_percent,
    }


@router.post("/{consent_id}/vote")
async def vote_consent(consent_id: str, data: VoteConsentSchema):
    conn = get_db_connection()
    cst = conn.execute("SELECT * FROM consent_requests WHERE id = ?", (consent_id,)).fetchone()
    if not cst:
        conn.close()
        raise HTTPException(status_code=404, detail="Consent request not found")

    new_status = "approved" if data.approved else "rejected"
    conn.execute("UPDATE consent_requests SET status = ? WHERE id = ?", (new_status, consent_id))
    conn.commit()
    conn.close()

    return {"consent_id": consent_id, "status": new_status}
