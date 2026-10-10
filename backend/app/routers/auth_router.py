import time
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.auth import create_access_token, create_refresh_token, decode_token, get_current_user
from app.config import settings
from app.database import get_db_connection, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])


class RegisterPassengerSchema(BaseModel):
    name: str
    email: str
    password: str
    phone: Optional[str] = None


class RegisterDriverSchema(BaseModel):
    name: str
    email: str
    password: str
    phone: Optional[str] = None
    vehicle_tier: str
    license_plate: str
    driver_license_number: str


class LoginSchema(BaseModel):
    email: str
    password: str


class RefreshSchema(BaseModel):
    refresh_token: str


@router.post("/register/passenger", status_code=status.HTTP_201_CREATED)
def register_passenger(data: RegisterPassengerSchema):
    conn = get_db_connection()
    existing = conn.execute("SELECT id FROM users WHERE email = ?", (data.email.lower(),)).fetchone()
    if existing:
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")

    user_id = f"usr-pax-{int(time.time() * 1000)}"
    pwd_hash = hash_password(data.password)

    conn.execute("""
    INSERT INTO users (id, name, email, password_hash, phone, role)
    VALUES (?, ?, ?, ?, ?, 'passenger')
    """, (user_id, data.name, data.email.lower(), pwd_hash, data.phone))
    conn.commit()
    conn.close()

    access_token = create_access_token(user_id, "passenger")
    refresh_token = create_refresh_token(user_id)

    return {
        "user": {
            "id": user_id,
            "name": data.name,
            "email": data.email.lower(),
            "phone": data.phone,
            "role": "passenger",
        },
        "tokens": {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "expires_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 3600)),
        },
    }


@router.post("/register/driver", status_code=status.HTTP_201_CREATED)
def register_driver(data: RegisterDriverSchema):
    conn = get_db_connection()
    existing = conn.execute("SELECT id FROM users WHERE email = ?", (data.email.lower(),)).fetchone()
    if existing:
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")

    user_id = f"usr-drv-{int(time.time() * 1000)}"
    pwd_hash = hash_password(data.password)

    conn.execute("""
    INSERT INTO users (id, name, email, password_hash, phone, role, vehicle_tier, license_plate, driver_license_number)
    VALUES (?, ?, ?, ?, ?, 'driver', ?, ?, ?)
    """, (
        user_id,
        data.name,
        data.email.lower(),
        pwd_hash,
        data.phone,
        data.vehicle_tier,
        data.license_plate.upper(),
        data.driver_license_number.upper(),
    ))
    conn.commit()
    conn.close()

    access_token = create_access_token(user_id, "driver")
    refresh_token = create_refresh_token(user_id)

    return {
        "user": {
            "id": user_id,
            "name": data.name,
            "email": data.email.lower(),
            "phone": data.phone,
            "role": "driver",
            "vehicle_tier": data.vehicle_tier,
            "license_plate": data.license_plate.upper(),
            "driver_license_number": data.driver_license_number.upper(),
        },
        "tokens": {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "expires_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 3600)),
        },
    }


@router.post("/login")
def login(data: LoginSchema):
    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE email = ?", (data.email.lower(),)).fetchone()
    conn.close()

    if not user or not verify_password(data.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user_dict = dict(user)
    access_token = create_access_token(user_dict["id"], user_dict["role"])
    refresh_token = create_refresh_token(user_dict["id"])

    return {
        "user": {
            "id": user_dict["id"],
            "name": user_dict["name"],
            "email": user_dict["email"],
            "phone": user_dict.get("phone"),
            "role": user_dict["role"],
            "vehicle_tier": user_dict.get("vehicle_tier"),
            "license_plate": user_dict.get("license_plate"),
            "driver_license_number": user_dict.get("driver_license_number"),
        },
        "tokens": {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "expires_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 3600)),
        },
    }


@router.post("/refresh")
def refresh_token(data: RefreshSchema):
    payload = decode_token(data.refresh_token)
    user_id = payload.get("sub")
    if not user_id or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_access = create_access_token(user["id"], user["role"])
    new_refresh = create_refresh_token(user["id"])

    return {
        "access_token": new_access,
        "refresh_token": new_refresh,
        "expires_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 3600)),
    }


@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    return {
        "id": current_user["id"],
        "name": current_user["name"],
        "email": current_user["email"],
        "phone": current_user.get("phone"),
        "role": current_user["role"],
        "vehicle_tier": current_user.get("vehicle_tier"),
        "license_plate": current_user.get("license_plate"),
        "driver_license_number": current_user.get("driver_license_number"),
    }
