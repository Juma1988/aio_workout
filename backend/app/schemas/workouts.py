"""Workout schemas: session sync, history."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CompletedExerciseInput(BaseModel):
    exercise_uuid: str
    exercise_name: str
    sets_completed: int = Field(ge=1)
    reps_completed: int | None = Field(None, ge=0)
    duration_seconds: int | None = Field(None, ge=0)
    weight_kg: float | None = Field(None, ge=0)
    notes: str = ""


class CompletedExerciseResponse(BaseModel):
    id: UUID
    exercise_uuid: str
    exercise_name: str
    sets_completed: int
    reps_completed: int | None
    duration_seconds: int | None
    weight_kg: float | None
    notes: str

    model_config = {"from_attributes": True}


class WorkoutSessionInput(BaseModel):
    session_date: datetime
    week_number: int = Field(ge=1)
    day_number: int = Field(ge=1, le=7)
    focus: str
    duration_seconds: int = Field(ge=0)
    exercises: list[CompletedExerciseInput]
    steps_during: int = Field(default=0, ge=0)
    hydration_liters: float = Field(default=0, ge=0)
    notes: str | None = None


class WorkoutSessionResponse(BaseModel):
    id: UUID
    session_date: datetime
    week_number: int
    day_number: int
    focus: str
    duration_seconds: int
    steps_during: int
    hydration_liters: float
    exercises: list[CompletedExerciseResponse]
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class WorkoutHistory(BaseModel):
    sessions: list[WorkoutSessionResponse]
    total_workouts: int
    total_sets: int
    total_duration_seconds: int
    current_streak: int
    longest_streak: int
    completed_weeks: int
