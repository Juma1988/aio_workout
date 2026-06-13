"""User schemas: profile, update."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class UserProfile(BaseModel):
    id: UUID
    email: str
    display_name: str
    avatar_url: str | None = None
    date_of_birth: date | None = None
    gender: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    is_premium: bool = False
    timezone: str = "UTC"
    locale: str = "en"
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=100)
    avatar_url: str | None = None
    date_of_birth: date | None = None
    gender: str | None = None
    height_cm: float | None = Field(None, gt=0, lt=300)
    weight_kg: float | None = Field(None, gt=0, lt=500)
    timezone: str | None = None
    locale: str | None = None


class UserPublic(BaseModel):
    """Public profile for social features — no PII."""
    id: UUID
    display_name: str
    avatar_url: str | None = None

    model_config = {"from_attributes": True}
