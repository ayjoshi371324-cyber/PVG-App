import os
from pydantic import BaseModel


class Settings(BaseModel):
    PROJECT_NAME: str = "RouteMates Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", "ridepool.db")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "ridepool_secret_super_key_2026_game_theory_shur")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    DEMO_MODE: bool = os.getenv("DEMO_MODE", "true").lower() in ("true", "1", "yes")


settings = Settings()
