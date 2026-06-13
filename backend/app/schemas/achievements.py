"""Achievement schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AchievementDefinitionResponse(BaseModel):
    id: str
    title: str
    description: str
    icon_name: str
    category: str
    tier: str
    threshold_value: int
    threshold_type: str
    is_hidden: bool
    sort_order: int

    model_config = {"from_attributes": True}


class UserAchievementResponse(BaseModel):
    achievement: AchievementDefinitionResponse
    progress: int
    target: int
    is_unlocked: bool
    unlocked_at: datetime | None

    model_config = {"from_attributes": True}


class AchievementUnlockResponse(BaseModel):
    newly_unlocked: list[AchievementDefinitionResponse]
    progress_updates: list[UserAchievementResponse]


class AchievementStats(BaseModel):
    total_definitions: int
    unlocked_count: int
    completion_percent: float
    by_category: dict[str, dict[str, int]]  # category -> {total, unlocked}
    by_tier: dict[str, dict[str, int]]
