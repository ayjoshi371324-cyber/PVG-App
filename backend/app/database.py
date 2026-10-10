import sqlite3
import hashlib
import json
import os
from typing import Any, Dict, List, Optional
from app.config import settings


def get_db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(settings.DATABASE_PATH, timeout=10.0)
    conn.row_factory = sqlite3.Row
    return conn


def hash_password(password: str, salt: Optional[str] = None) -> str:
    if not salt:
        salt = os.urandom(16).hex()
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000)
    return f"{salt}${dk.hex()}"


def verify_password(plain_password: str, hashed: str) -> bool:
    try:
        salt, expected_hex = hashed.split("$")
        dk = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), salt.encode("utf-8"), 100000)
        return dk.hex() == expected_hex
    except Exception:
        return False


def init_db():
    conn = get_db_connection()
    cur = conn.cursor()

    # Users table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        vehicle_tier TEXT,
        license_plate TEXT,
        driver_license_number TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # Places table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS places (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        is_preset INTEGER DEFAULT 0
    );
    """)

    # Vehicles table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        license_plate TEXT NOT NULL,
        status TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        current_occupancy INTEGER DEFAULT 0,
        max_capacity INTEGER DEFAULT 4,
        battery_percentage INTEGER DEFAULT 80,
        assigned_route_name TEXT,
        onboard_seats INTEGER DEFAULT 0,
        reserved_seats INTEGER DEFAULT 0,
        held_seats INTEGER DEFAULT 0
    );
    """)

    # Bookings table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        passenger_name TEXT NOT NULL,
        pickup_name TEXT NOT NULL,
        pickup_lat REAL NOT NULL,
        pickup_lng REAL NOT NULL,
        dropoff_name TEXT NOT NULL,
        dropoff_lat REAL NOT NULL,
        dropoff_lng REAL NOT NULL,
        party_size INTEGER DEFAULT 1,
        tier TEXT NOT NULL,
        status TEXT NOT NULL,
        fare REAL DEFAULT 0.0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # Trips table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS trips (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        driver_id TEXT,
        status TEXT NOT NULL,
        total_shared_km REAL DEFAULT 0.0,
        fare REAL DEFAULT 0.0,
        otp_code TEXT,
        otp_verified INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # Consent Requests table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS consent_requests (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        booking_id TEXT NOT NULL,
        new_passenger_name TEXT NOT NULL,
        new_detour_percent REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # Payments table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        order_id TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        status TEXT NOT NULL,
        payment_id TEXT,
        payment_method TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    conn.commit()

    # Seed demo users if empty
    cur.execute("SELECT COUNT(*) as count FROM users")
    if cur.fetchone()["count"] == 0:
        demo_pass = hash_password("password123")
        cur.executemany("""
        INSERT INTO users (id, name, email, password_hash, phone, role, vehicle_tier, license_plate, driver_license_number)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            ("usr-demo-pax-1", "Pooja Sharma", "passenger@ridepool.ai", demo_pass, "+91 98234 56789", "passenger", None, None, None),
            ("usr-demo-drv-1", "Santosh Tambe", "driver@ridepool.ai", demo_pass, "+91 98901 23456", "driver", "car", "MH 12 RN 8842", "DL-MH12-2022-9842"),
            ("usr-demo-ops-1", "Fleet Controller", "ops@ridepool.ai", demo_pass, "+91 98000 11223", "ops", None, None, None),
        ])

    # Seed Pune landmarks if empty
    cur.execute("SELECT COUNT(*) as count FROM places")
    if cur.fetchone()["count"] == 0:
        pune_places = [
            ("kothrud", "Kothrud Stand", "Kothrud, Pune, Maharashtra 411038", 18.5074, 73.8077, 1),
            ("hinjawadi", "Hinjawadi Phase 1", "Rajiv Gandhi Infotech Park, Hinjawadi, Pune 411057", 18.5913, 73.7389, 1),
            ("shivajinagar", "Shivaji Nagar Station", "Shivaji Nagar, Pune, Maharashtra 411005", 18.5314, 73.8446, 1),
            ("viman_nagar", "Viman Nagar (Phoenix)", "Viman Nagar, Pune, Maharashtra 411014", 18.5679, 73.9143, 1),
            ("swargate", "Swargate Bus Station", "Swargate, Pune, Maharashtra 411042", 18.5018, 73.8636, 1),
            ("hadapsar", "Hadapsar Magarpatta", "Magarpatta City, Hadapsar, Pune 411028", 18.5089, 73.9260, 1),
            ("baner", "Baner High Street", "Baner Road, Pune, Maharashtra 411045", 18.5590, 73.7868, 1),
            ("koregaon_park", "Koregaon Park (North Main Rd)", "Koregaon Park, Pune, Maharashtra 411001", 18.5362, 73.8940, 1),
        ]
        cur.executemany("""
        INSERT INTO places (id, name, address, latitude, longitude, is_preset)
        VALUES (?, ?, ?, ?, ?, ?)
        """, pune_places)

    # Seed Fleet Vehicles if empty
    cur.execute("SELECT COUNT(*) as count FROM vehicles")
    if cur.fetchone()["count"] == 0:
        initial_fleet = [
            ("EV-01", "Tata Tigor EV", "MH 12 RN 4001", "idle", 18.5018, 73.8636, 0, 4, 88, None, 0, 0, 0),
            ("EV-02", "Tata Tigor EV", "MH 12 RN 4002", "pickingUp", 18.5074, 73.8077, 1, 4, 79, "Kothrud-Hinjawadi Corridor", 1, 1, 0),
            ("EV-03", "Tata Nexon EV", "MH 12 RN 5100", "inPool", 18.5913, 73.7389, 3, 4, 65, "ShivajiNagar-Hinjawadi Express", 2, 1, 0),
            ("EV-04", "Tata Tigor EV", "MH 12 RN 8842", "inPool", 18.5314, 73.8446, 2, 4, 84, "Central-West IT Pool", 2, 0, 1),
            ("EV-05", "Tata Tigor EV", "MH 12 RN 6012", "pickingUp", 18.5679, 73.9143, 1, 4, 92, "East Corridor Shuttle", 1, 0, 1),
            ("EV-06", "Tata Nexon EV", "MH 12 RN 7200", "idle", 18.5089, 73.9260, 0, 4, 81, None, 0, 0, 0),
        ]
        cur.executemany("""
        INSERT INTO vehicles (id, name, license_plate, status, latitude, longitude, current_occupancy, max_capacity, battery_percentage, assigned_route_name, onboard_seats, reserved_seats, held_seats)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, initial_fleet)

    conn.commit()
    conn.close()
