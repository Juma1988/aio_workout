"""Goal schemas: create, update, track progress."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class GoalCreate(BaseModel):
    goal_type: str = Field(description="daily, weekly, monthly, custom")
    target_steps: int = Field(gt=0)
    start_date: date
    end_date: date | None = None


class GoalUpdate(BaseModel):
    target_steps: int | None = Field(None, gt=0)
    end_date: date | None = None
    is_active: bool | None = None


class GoalResponse(BaseModel):
    id: UUID
    goal_type: str
    target_steps: int
    start_date: date
    end_date: date | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class GoalProgress(BaseModel):
    goal: GoalResponse
    current_steps: int
    target_steps: int
    progress_percent: float
    days_remaining: int | None
    is_achieved: bool
    streak_days: int  # consecutive days meeting the goal
    projected_completion_date: date | None


class GoalHistory(BaseModel):
    goal: GoalResponse
    achieved_dates: list[date]
    total_days: int
    achieved_days: int
    completion_rate: float
