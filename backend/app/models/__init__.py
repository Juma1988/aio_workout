"""Models package — import all models so Alembic and SQLAlchemy see them."""

from app.models.user import User
from app.models.device import Device
from app.models.step_record import StepRecord, DailyStepSummary
from app.models.step_goal import StepGoal
from app.models.workout import WorkoutSession, CompletedExercise
from app.models.weight import WeightEntry
from app.models.achievement import AchievementDefinition, UserAchievement
from app.models.social import (
    FriendRequest,
    Friendship,
    Challenge,
    ChallengeParticipant,
    LeaderboardEntry,
)

__all__ = [
    "User",
    "Device",
    "StepRecord",
    "DailyStepSummary",
    "StepGoal",
    "WorkoutSession",
    "CompletedExercise",
    "WeightEntry",
    "AchievementDefinition",
    "UserAchievement",
    "FriendRequest",
    "Friendship",
    "Challenge",
    "ChallengeParticipant",
    "LeaderboardEntry",
]
