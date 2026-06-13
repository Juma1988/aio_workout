"""Analytics endpoints: hourly distribution, weekly comparison, heatmap."""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import SuccessResponse
from app.services import analytics_service

router = APIRouter()


@router.get(
    "/hourly/{target_date}",
    summary="Get hourly step distribution for a date",
)
async def get_hourly(
    target_date: date,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    distribution = await analytics_service.get_hourly_distribution(db, user.id, target_date)
    return SuccessResponse(data=distribution)


@router.get(
    "/weekly-comparison",
    summary="Compare this week vs last week",
)
async def get_weekly_comparison(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    comparison = await analytics_service.get_weekly_comparison(db, user.id)
    return SuccessResponse(data=comparison)


@router.get(
    "/monthly-heatmap/{year}/{month}",
    summary="Get monthly step heatmap data",
)
async def get_monthly_heatmap(
    year: int,
    month: int,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    if month < 1 or month > 12:
        return SuccessResponse(data=[])
    heatmap = await analytics_service.get_monthly_heatmap(db, user.id, year, month)
    return SuccessResponse(data=heatmap)
