"""Social schemas: friends, challenges, leaderboards."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.user import UserPublic


# ── Friend requests ──
class FriendRequestSend(BaseModel):
    user_id: UUID


class FriendRequestResponse(BaseModel):
    id: UUID
    sender: UserPublic
    receiver: UserPublic
    status: str
    created_at: datetime


class FriendListResponse(BaseModel):
    friends: list[UserPublic]
    count: int


# ── Challenges ──
class ChallengeCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    challenge_type: str  # daily_steps, weekly_steps, total_steps, streak, distance
    target_value: int = Field(gt=0)
    start_date: date
    end_date: date
    invite_user_ids: list[UUID] = []


class ChallengeResponse(BaseModel):
    id: UUID
    creator: UserPublic
    title: str
    challenge_type: str
    target_value: int
    start_date: date
    end_date: date
    status: str
    created_at: datetime
    participant_count: int

    model_config = {"from_attributes": True}


class ChallengeParticipantResponse(BaseModel):
    user: UserPublic
    current_value: int
    target_value: int
    progress_percent: float
    rank: int
    completed_at: datetime | None


class ChallengeDetail(BaseModel):
    challenge: ChallengeResponse
    participants: list[ChallengeParticipantResponse]
    my_rank: int | None
    my_progress: int | None


# ── Leaderboard ──
class LeaderboardEntryResponse(BaseModel):
    rank: int
    user: UserPublic
    total_steps: int
    is_friend: bool = False


class LeaderboardResponse(BaseModel):
    period_type: str
    period_start: date
    entries: list[LeaderboardEntryResponse]
    my_rank: int | None
    my_total_steps: int | None
