from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"


def test_places_search():
    res = client.get("/places/search?q=kothrud")
    assert res.status_code == 200
    data = res.json()
    assert len(data) > 0
    assert "Kothrud" in data[0]["name"]


def test_vehicles_fleet_list():
    res = client.get("/vehicles")
    assert res.status_code == 200
    vehicles = res.json()
    assert len(vehicles) >= 6
    # Check cabin breakdown fields
    v = vehicles[0]
    assert "onboard_seats" in v
    assert "reserved_seats" in v
    assert "held_seats" in v
    assert "free_seats" in v


def test_ops_benchmark():
    res = client.get("/ops/benchmark?seed=42")
    assert res.status_code == 200
    data = res.json()
    assert data["vkt_algorithmic"] < data["vkt_greedy"]
    assert data["vkt_savings_km"] > 0
    assert data["detour_algorithmic"] <= 15.0
    assert data["p95_detour_algorithmic"] <= 15.0
    assert data["service_rate_algorithmic"] >= data["service_rate_greedy"]


def test_booking_trip_and_payment_flow():
    # Login passenger
    login_res = client.post("/auth/login", json={
        "email": "passenger@ridepool.ai",
        "password": "password123"
    })
    token = login_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create booking
    bkg_res = client.post("/bookings", json={
        "passenger_name": "Pooja Sharma",
        "pickup_name": "Kothrud Stand",
        "pickup_lat": 18.5074,
        "pickup_lng": 73.8077,
        "dropoff_name": "Hinjawadi Phase 1",
        "dropoff_lat": 18.5913,
        "dropoff_lng": 73.7389,
        "party_size": 1,
        "tier": "car",
        "fare": 78.33
    }, headers=headers)
    assert bkg_res.status_code == 201
    booking_id = bkg_res.json()["id"]

    # Start Trip
    trip_res = client.post("/trips/start", json={
        "vehicle_id": "EV-02",
        "booking_id": booking_id,
        "total_shared_km": 12.0,
        "fare": 140.0
    }, headers=headers)
    assert trip_res.status_code == 201
    trip_id = trip_res.json()["trip_id"]
    otp = trip_res.json()["otp"]

    # Verify OTP
    verify_res = client.post(f"/trips/{trip_id}/verify-otp", json={"otp": otp})
    assert verify_res.status_code == 200
    assert verify_res.json()["status"] == "verified"

    # Payment order
    order_res = client.post("/payments/order", json={
        "booking_id": booking_id,
        "amount_rupees": 78.33
    })
    assert order_res.status_code == 201
    order_id = order_res.json()["order_id"]

    # Verify payment
    pay_verify_res = client.post("/payments/verify", json={
        "order_id": order_id,
        "payment_id": "pay_test_12345"
    })
    assert pay_verify_res.status_code == 200
    assert pay_verify_res.json()["verified"] is True

    # Complete trip
    comp_res = client.post(f"/trips/{trip_id}/complete")
    assert comp_res.status_code == 200

    # Get receipt
    receipt_res = client.get(f"/payments/receipt/{booking_id}")
    assert receipt_res.status_code == 200
    assert receipt_res.json()["status"] == "paid"
    assert receipt_res.json()["fare_rupees"] == 78.33
