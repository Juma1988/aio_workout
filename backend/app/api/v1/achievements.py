"""Achievement endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.achievements import (
    AchievementStats,
    UserAchievementResponse,
)
from app.schemas.common import SuccessResponse

router = APIRouter()


@router.get(
    "/",
    response_model=SuccessResponse[list[UserAchievementResponse]],
    summary="Get all achievements with progress",
)
async def list_achievements(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        text("""
            SELECT
                ad.id as ach_id, ad.title, ad.description, ad.icon_name,
                ad.category, ad.tier, ad.threshold_value, ad.threshold_type,
                ad.is_hidden, ad.sort_order,
                COALESCE(ua.progress, 0) as progress,
                ua.unlocked_at
            FROM achievement_definitions ad
            LEFT JOIN user_achievements ua
                ON ua.achievement_id = ad.id AND ua.user_id = :uid
            ORDER BY ad.sort_order, ad.id
        """),
        {"uid": str(user.id)},
    )

    achievements = []
    for r in result.fetchall():
        achievements.append(UserAchievementResponse(
            achievement={
                "id": r.ach_id,
                "title": r.title,
                "description": r.description,
                "icon_name": r.icon_name,
                "category": r.category,
                "tier": r.tier,
                "threshold_value": r.threshold_value,
                "threshold_type": r.threshold_type,
                "is_hidden": r.is_hidden,
                "sort_order": r.sort_order,
            },
            progress=r.progress,
            target=r.threshold_value,
            is_unlocked=r.unlocked_at is not None,
            unlocked_at=r.unlocked_at,
        ))

    return SuccessResponse(data=achievements)


@router.get(
    "/stats",
    response_model=SuccessResponse[AchievementStats],
    summary="Get achievement statistics",
)
async def get_stats(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    total_result = await db.execute(
        text("SELECT COUNT(*) FROM achievement_definitions WHERE is_hidden = FALSE")
    )
    total = total_result.scalar() or 0

    unlocked_result = await db.execute(
        text("""
            SELECT COUNT(*) FROM user_achievements
            WHERE user_id = :uid AND unlocked_at IS NOT NULL
        """),
        {"uid": str(user.id)},
    )
    unlocked = unlocked_result.scalar() or 0

    return SuccessResponse(data=AchievementStats(
        total_definitions=total,
        unlocked_count=unlocked,
        completion_percent=round(unlocked / max(total, 1) * 100, 1),
        by_category={},
        by_tier={},
    ))
