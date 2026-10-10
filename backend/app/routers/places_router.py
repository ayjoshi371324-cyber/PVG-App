from typing import List, Optional
from fastapi import APIRouter, Query
from pydantic import BaseModel
from app.database import get_db_connection

router = APIRouter(prefix="/places", tags=["Places & Geocoding"])


class PlaceSchema(BaseModel):
    id: str
    name: str
    address: str
    latitude: float
    longitude: float
    is_preset: bool


@router.get("/search", response_model=List[PlaceSchema])
def search_places(q: str = Query(..., min_length=1)):
    conn = get_db_connection()
    like_query = f"%{q.lower()}%"
    rows = conn.execute(
        "SELECT * FROM places WHERE LOWER(name) LIKE ? OR LOWER(address) LIKE ? LIMIT 10",
        (like_query, like_query),
    ).fetchall()
    conn.close()

    return [
        PlaceSchema(
            id=r["id"],
            name=r["name"],
            address=r["address"],
            latitude=r["latitude"],
            longitude=r["longitude"],
            is_preset=bool(r["is_preset"]),
        )
        for r in rows
    ]


@router.get("/reverse", response_model=Optional[PlaceSchema])
def reverse_geocode(lat: float, lng: float):
    conn = get_db_connection()
    # Find nearest place using Euclidean distance approximation
    rows = conn.execute("SELECT * FROM places").fetchall()
    conn.close()

    if not rows:
        return None

    closest = min(
        rows,
        key=lambda r: ((r["latitude"] - lat) ** 2 + (r["longitude"] - lng) ** 2),
    )

    return PlaceSchema(
        id=closest["id"],
        name=closest["name"],
        address=closest["address"],
        latitude=closest["latitude"],
        longitude=closest["longitude"],
        is_preset=bool(closest["is_preset"]),
    )
