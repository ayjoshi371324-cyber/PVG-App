from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import init_db
from app.routers import (
    auth_router,
    bookings_router,
    consent_router,
    ops_router,
    payments_router,
    places_router,
    trips_router,
    vehicles_router,
)
from app.websockets import ws_manager


# Ensure SQLite tables exist
init_db()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite schema and seed demo data on startup
    init_db()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    lifespan=lifespan,
)

# CORS middleware for Flutter web/desktop/mobile access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount REST API routers
app.include_router(auth_router.router)
app.include_router(places_router.router)
app.include_router(vehicles_router.router)
app.include_router(bookings_router.router)
app.include_router(trips_router.router)
app.include_router(consent_router.router)
app.include_router(payments_router.router)
app.include_router(ops_router.router)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "RouteMates Backend Bridge",
        "version": settings.VERSION,
        "demo_mode": settings.DEMO_MODE,
    }


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            # Keep connection open, receive any incoming telemetry/pings
            data = await websocket.receive_text()
            # Echo back receipt / heartbeat
            await websocket.send_text(f'{{"event":"ack","message":"received"}}')
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception:
        ws_manager.disconnect(websocket)
