"""Step record and daily summary models."""

import uuid

from sqlalchemy import (
    CheckConstraint,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID

from app.database import Base


class StepRecord(Base):
    __tablename__ = "step_records"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="SET NULL"), nullable=True)
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    bucket_minutes = Column(SmallInteger, nullable=False, default=60)
    step_count = Column(Integer, nullable=False, default=0)
    distance_meters = Column(Numeric(8, 2), nullable=True)
    calories = Column(Numeric(6, 1), nullable=True)
    source = Column(String(30), nullable=False, default="phone")
    metadata_ = Column("metadata", JSONB, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        CheckConstraint("step_count >= 0", name="ck_step_count_non_negative"),
        CheckConstraint("distance_meters >= 0", name="ck_distance_non_negative"),
        CheckConstraint("calories >= 0", name="ck_calories_non_negative"),
        CheckConstraint("bucket_minutes IN (1, 5, 15, 30, 60)", name="ck_bucket_valid"),
        CheckConstraint("source IN ('phone', 'watch', 'healthkit', 'google_fit', 'manual')", name="ck_source_valid"),
        Index("idx_step_records_user_time", "user_id", "recorded_at"),
        {"extend_existing": True},
    )


class DailyStepSummary(Base):
    __tablename__ = "daily_step_summaries"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    date = Column(Date, primary_key=True)
    total_steps = Column(Integer, nullable=False, default=0)
    total_distance = Column(Numeric(10, 2), nullable=False, default=0)
    total_calories = Column(Numeric(8, 1), nullable=False, default=0)
    active_minutes = Column(Integer, nullable=False, default=0)
    peak_step_hour = Column(SmallInteger, nullable=True)
    data_points = Column(Integer, nullable=False, default=0)
    sources = Column(ARRAY(Text), nullable=False, default=list)
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_daily_steps_date", "date"),
        Index("idx_daily_steps_user_date", "user_id", "date"),
    )
