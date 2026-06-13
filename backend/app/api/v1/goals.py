"""Goal endpoints: CRUD, progress tracking."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import MessageResponse, SuccessResponse
from app.schemas.goals import GoalCreate, GoalProgress, GoalResponse, GoalUpdate
from app.services import goal_service

router = APIRouter()


@router.post(
    "/",
    response_model=SuccessResponse[GoalResponse],
    status_code=201,
    summary="Create a new step goal",
)
async def create_goal(
    body: GoalCreate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    goal = await goal_service.create_goal(db, user.id, body)
    return SuccessResponse(data=goal)


@router.get(
    "/",
    response_model=SuccessResponse[list[GoalResponse]],
    summary="List all goals",
)
async def list_goals(
    user: CurrentUser,
    active_only: bool = True,
    db: AsyncSession = Depends(get_db),
):
    goals = await goal_service.list_goals(db, user.id, active_only)
    return SuccessResponse(data=goals)


@router.put(
    "/{goal_id}",
    response_model=SuccessResponse[GoalResponse],
    summary="Update a goal",
)
async def update_goal(
    goal_id: UUID,
    body: GoalUpdate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    goal = await goal_service.update_goal(db, user.id, goal_id, body)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return SuccessResponse(data=goal)


@router.get(
    "/{goal_id}/progress",
    response_model=SuccessResponse[GoalProgress],
    summary="Get goal progress with streak",
)
async def get_progress(
    goal_id: UUID,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    progress = await goal_service.get_goal_progress(db, user.id, goal_id)
    if not progress:
        raise HTTPException(status_code=404, detail="Goal not found")
    return SuccessResponse(data=progress)


@router.delete(
    "/{goal_id}",
    response_model=MessageResponse,
    summary="Deactivate a goal",
)
async def deactivate_goal(
    goal_id: UUID,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    goal = await goal_service.update_goal(
        db, user.id, goal_id, GoalUpdate(is_active=False)
    )
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return MessageResponse(message="Goal deactivated")
