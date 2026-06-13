"""Achievement models."""

import uuid

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class AchievementDefinition(Base):
    __tablename__ = "achievement_definitions"

    id = Column(String(50), primary_key=True)
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    icon_name = Column(String(50), nullable=False)
    category = Column(String(30), nullable=False)  # workout, steps, streak, weight, social, special
    tier = Column(String(10), nullable=False, default="bronze")
    threshold_value = Column(Integer, nullable=False, default=1)
    threshold_type = Column(String(30), nullable=False, default="count")
    is_hidden = Column(Boolean, nullable=False, default=False)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())


class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(String(50), ForeignKey("achievement_definitions.id"), nullable=False)
    progress = Column(Integer, nullable=False, default=0)
    unlocked_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_user_achievements_user", "user_id", "unlocked_at"),
    )
