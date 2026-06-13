"""Step schemas: sync, records, summaries, stats."""

from datetime import date, datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


# ── Sync (bulk upload from device) ──
class StepRecordInput(BaseModel):
    recorded_at: datetime
    bucket_minutes: int = Field(default=60, ge=1, le=60)
    step_count: int = Field(ge=0)
    distance_meters: float | None = Field(None, ge=0)
    calories: float | None = Field(None, ge=0)
    source: str = Field(default="phone")
    metadata: dict[str, Any] = {}


class StepSyncRequest(BaseModel):
    device_id: str | None = None
    records: list[StepRecordInput] = Field(max_length=500)


class StepSyncResponse(BaseModel):
    synced: int
    duplicates_skipped: int
    summary_date: date


# ── Single record ──
class StepRecordResponse(BaseModel):
    id: UUID
    recorded_at: datetime
    bucket_minutes: int
    step_count: int
    distance_meters: float | None
    calories: float | None
    source: str

    model_config = {"from_attributes": True}


# ── Daily summary ──
class DailyStepSummaryResponse(BaseModel):
    date: date
    total_steps: int
    total_distance: float
    total_calories: float
    active_minutes: int
    peak_step_hour: int | None
    sources: list[str]

    model_config = {"from_attributes": True}


# ── Stats ──
class StepStats(BaseModel):
    period: str  # "daily", "weekly", "monthly"
    start_date: date
    end_date: date
    total_steps: int
    average_steps: float
    max_steps: int
    min_steps: int
    total_distance: float
    total_calories: float
    days_with_data: int
    daily_breakdown: list[DailyStepSummaryResponse]


class HourlyDistribution(BaseModel):
    hour: int  # 0-23
    avg_steps: float


class StepTrend(BaseModel):
    current_period_avg: float
    previous_period_avg: float
    change_percent: float
    trend: str  # "up", "down", "stable"
