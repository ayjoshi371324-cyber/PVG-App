from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_auth_passenger_registration_and_login():
    email = "test.pax@example.com"
    # Register passenger
    res = client.post("/auth/register/passenger", json={
        "name": "Ananya Deshpande",
        "email": email,
        "password": "secretpassword",
        "phone": "+91 9988776655"
    })
    assert res.status_code == 201
    data = res.json()
    assert data["user"]["role"] == "passenger"
    assert "access_token" in data["tokens"]
    access_token = data["tokens"]["access_token"]
    refresh_token = data["tokens"]["refresh_token"]

    # Access /auth/me with token
    me_res = client.get("/auth/me", headers={"Authorization": f"Bearer {access_token}"})
    assert me_res.status_code == 200
    assert me_res.json()["email"] == email

    # Refresh token
    ref_res = client.post("/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_res.status_code == 200
    assert "access_token" in ref_res.json()


def test_auth_driver_registration():
    email = "test.driver@example.com"
    res = client.post("/auth/register/driver", json={
        "name": "Kishore Shinde",
        "email": email,
        "password": "driverpassword",
        "phone": "+91 98221 55667",
        "vehicle_tier": "car",
        "license_plate": "MH 12 RN 8842",
        "driver_license_number": "DL-MH12-2022-9842"
    })
    assert res.status_code == 201
    data = res.json()
    assert data["user"]["role"] == "driver"
    assert data["user"]["vehicle_tier"] == "car"
    assert data["user"]["license_plate"] == "MH 12 RN 8842"
    assert data["user"]["driver_license_number"] == "DL-MH12-2022-9842"


def test_demo_accounts_login():
    # Login demo passenger
    res = client.post("/auth/login", json={
        "email": "passenger@ridepool.ai",
        "password": "password123"
    })
    assert res.status_code == 200
    assert res.json()["user"]["role"] == "passenger"

    # Login demo driver
    res_drv = client.post("/auth/login", json={
        "email": "driver@ridepool.ai",
        "password": "password123"
    })
    assert res_drv.status_code == 200
    assert res_drv.json()["user"]["role"] == "driver"
    assert res_drv.json()["user"]["license_plate"] == "MH 12 RN 8842"
