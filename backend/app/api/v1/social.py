"""Social endpoints: friends, challenges, leaderboards."""

from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import MessageResponse, SuccessResponse
from app.schemas.social import (
    ChallengeCreate,
    ChallengeDetail,
    FriendListResponse,
    LeaderboardResponse,
)
from app.services import social_service

router = APIRouter()


# ── Friends ──
@router.post(
    "/friends/request",
    response_model=MessageResponse,
    summary="Send a friend request",
)
async def send_friend_request(
    body: dict,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    receiver_id = UUID(body["user_id"])
    if receiver_id == user.id:
        raise HTTPException(status_code=400, detail="Cannot friend yourself")
    try:
        await social_service.send_friend_request(db, user.id, receiver_id)
        return MessageResponse(message="Friend request sent")
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.post(
    "/friends/accept/{request_id}",
    response_model=MessageResponse,
    summary="Accept a friend request",
)
async def accept_friend_request(
    request_id: UUID,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    try:
        await social_service.accept_friend_request(db, request_id, user.id)
        return MessageResponse(message="Friend request accepted")
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get(
    "/friends",
    response_model=SuccessResponse[FriendListResponse],
    summary="Get friends list",
)
async def get_friends(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    friends = await social_service.get_friends(db, user.id)
    return SuccessResponse(data=friends)


# ── Challenges ──
@router.post(
    "/challenges",
    response_model=SuccessResponse,
    status_code=201,
    summary="Create a challenge",
)
async def create_challenge(
    body: ChallengeCreate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    challenge = await social_service.create_challenge(db, user.id, body)
    return SuccessResponse(data=challenge)


# ── Leaderboard ──
@router.get(
    "/leaderboard",
    response_model=SuccessResponse[LeaderboardResponse],
    summary="Get leaderboard for a period",
)
async def get_leaderboard(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
    period_type: str = Query(description="daily, weekly, monthly"),
    period_start: date = Query(description="Period start date"),
):
    if period_type not in ("daily", "weekly", "monthly"):
        raise HTTPException(status_code=400, detail="Invalid period_type")
    leaderboard = await social_service.get_leaderboard(db, user.id, period_type, period_start)
    return SuccessResponse(data=leaderboard)
