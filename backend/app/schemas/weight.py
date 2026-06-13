"""Weight schemas."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class WeightEntryInput(BaseModel):
    entry_date: date
    weight_kg: float = Field(gt=0, lt=500)
    notes: str | None = None
    source: str = "manual"


class WeightEntryResponse(BaseModel):
    id: UUID
    entry_date: date
    weight_kg: float
    notes: str | None
    source: str
    created_at: datetime

    model_config = {"from_attributes": True}


class WeightStats(BaseModel):
    current_weight: float | None
    start_weight: float | None
    change_kg: float | None
    change_percent: float | None
    trend: str  # "losing", "gaining", "stable", "no_data"
    bmi: float | None
    bmi_category: str | None
    entries_count: int
