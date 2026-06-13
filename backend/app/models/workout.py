"""Workout session and completed exercise models."""

import uuid

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    session_date = Column(DateTime(timezone=True), nullable=False)
    week_number = Column(Integer, nullable=False)
    day_number = Column(Integer, nullable=False)
    focus = Column(String(100), nullable=False)
    duration_seconds = Column(Integer, nullable=False, default=0)
    steps_during = Column(Integer, nullable=False, default=0)
    hydration_liters = Column(Numeric(4, 2), nullable=False, default=0)
    notes = Column(Text, nullable=True)
    synced_from_device = Column(Boolean, nullable=False, default=False)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_sessions_user_date", "user_id", "session_date"),
        {"extend_existing": True},
    )


class CompletedExercise(Base):
    __tablename__ = "completed_exercises"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("workout_sessions.id", ondelete="CASCADE"), nullable=False)
    exercise_uuid = Column(String(100), nullable=False)
    exercise_name = Column(String(200), nullable=False)
    sets_completed = Column(Integer, nullable=False)
    reps_completed = Column(Integer, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    weight_kg = Column(Numeric(6, 1), nullable=True)
    notes = Column(Text, nullable=False, default="")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_completed_exercises_session", "session_id"),
    )
