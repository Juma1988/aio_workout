"""Notification and device schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


# ── Device registration ──
class DeviceRegister(BaseModel):
    device_type: str = Field(description="ios, android, watchos, wearos, web")
    device_name: str = ""
    os_version: str | None = None
    app_version: str | None = None
    push_token: str | None = None
    push_provider: str = "none"  # fcm, apns, none


class DeviceResponse(BaseModel):
    id: UUID
    device_type: str
    device_name: str
    os_version: str | None
    app_version: str | None
    is_active: bool
    last_sync_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Notification preferences ──
class NotificationPreferences(BaseModel):
    daily_reminder: bool = True
    daily_reminder_hour: int = 8
    daily_reminder_minute: int = 0
    missed_workout: bool = False
    achievement_unlocked: bool = True
    goal_reminder: bool = True
    weekly_progress: bool = True
    challenge_update: bool = True
    quiet_hours_enabled: bool = False
    quiet_hours_start: int = 22  # hour (0-23)
    quiet_hours_end: int = 7


class NotificationLogEntry(BaseModel):
    id: UUID
    notification_type: str
    title: str
    body: str
    data: dict = {}
    sent_at: datetime
    delivered: bool
    opened: bool
