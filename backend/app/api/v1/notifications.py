"""Notification endpoints: preferences, history."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import SuccessResponse
from app.schemas.notifications import NotificationPreferences
from app.services import notification_service

router = APIRouter()


@router.get(
    "/preferences",
    response_model=SuccessResponse[NotificationPreferences],
    summary="Get notification preferences",
)
async def get_preferences(user: CurrentUser):
    # TODO: Load from user_preferences table
    return SuccessResponse(data=NotificationPreferences())


@router.put(
    "/preferences",
    response_model=SuccessResponse[NotificationPreferences],
    summary="Update notification preferences",
)
async def update_preferences(
    body: NotificationPreferences,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    import json
    from sqlalchemy import text

    await db.execute(
        text("""
            INSERT INTO user_preferences (user_id, pref_key, pref_value)
            VALUES (:uid, 'notifications', :val)
            ON CONFLICT (user_id, pref_key) DO UPDATE SET pref_value = EXCLUDED.pref_value
        """),
        {"uid": str(user.id), "val": json.dumps(body.model_dump())},
    )
    return SuccessResponse(data=body)


@router.get(
    "/history",
    response_model=SuccessResponse[list[dict]],
    summary="Get notification history",
)
async def get_history(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    history = await notification_service.get_notification_history(db, user.id)
    return SuccessResponse(data=history)
