"""Application settings via pydantic-settings."""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── App ──
    APP_NAME: str = "aio-workout-api"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: Literal["development", "staging", "production"] = "development"

    # ── Database ──
    DATABASE_URL: str = "postgresql+asyncpg://aio_workout:secret@localhost:5432/aio_workout"
    DATABASE_ECHO: bool = False
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10

    # ── Redis ──
    REDIS_URL: str = "redis://localhost:6379/0"
    CACHE_TTL_SECONDS: int = 300  # 5 min default

    # ── Auth ──
    JWT_SECRET_KEY: str = "CHANGE-ME-IN-PRODUCTION"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    BCRYPT_ROUNDS: int = 12

    # ── Rate Limiting ──
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW_SECONDS: int = 60

    # ── Push Notifications ──
    FIREBASE_CREDENTIALS_PATH: str = ""

    # ── CORS ──
    CORS_ORIGINS: list[str] = ["*"]

    # ── Aggregation ──
    STEP_BUCKET_MINUTES: int = 15  # granularity of step sync


@lru_cache()
def get_settings() -> Settings:
    return Settings()
