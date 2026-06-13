"""Workout endpoints: sync from device, history."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import SuccessResponse
from app.schemas.workouts import (
    WorkoutHistory,
    WorkoutSessionInput,
    WorkoutSessionResponse,
)
from app.services import workout_service

router = APIRouter()


@router.post(
    "/sync",
    response_model=SuccessResponse[WorkoutSessionResponse],
    summary="Sync a workout session from device",
)
async def sync_workout(
    body: WorkoutSessionInput,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    result = await workout_service.sync_workout(db, user.id, body)
    return SuccessResponse(data=result)


@router.get(
    "/history",
    response_model=SuccessResponse[WorkoutHistory],
    summary="Get workout history with stats",
)
async def get_history(
    user: CurrentUser,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    history = await workout_service.get_workout_history(db, user.id, limit, offset)
    return SuccessResponse(data=history)
