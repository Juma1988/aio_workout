"""Step endpoints: sync, query, stats."""

from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser, Pagination, RedisClient
from app.schemas.common import CursorPage, SuccessResponse
from app.schemas.steps import (
    DailyStepSummaryResponse,
    StepRecordResponse,
    StepStats,
    StepSyncRequest,
    StepSyncResponse,
    StepTrend,
)
from app.services import step_service

router = APIRouter()


@router.post(
    "/sync",
    response_model=SuccessResponse[StepSyncResponse],
    summary="Sync step data from device",
)
async def sync_steps(
    body: StepSyncRequest,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Bulk upload step records from device. Deduplicates by (user_id, timestamp, source)."""
    result = await step_service.sync_steps(
        db, user.id, body.device_id, body.records
    )
    return SuccessResponse(data=result)


@router.get(
    "/today",
    response_model=SuccessResponse[DailyStepSummaryResponse],
    summary="Get today's step summary",
)
async def get_today(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    summary = await step_service.get_daily_summary(db, user.id, today)
    return SuccessResponse(data=summary)


@router.get(
    "/daily/{target_date}",
    response_model=SuccessResponse[DailyStepSummaryResponse],
    summary="Get step summary for a specific date",
)
async def get_daily(
    target_date: date,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    summary = await step_service.get_daily_summary(db, user.id, target_date)
    return SuccessResponse(data=summary)


@router.get(
    "/stats",
    response_model=SuccessResponse[StepStats],
    summary="Get step statistics for a date range",
)
async def get_stats(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
    start_date: date = Query(description="Start date (inclusive)"),
    end_date: date = Query(description="End date (inclusive)"),
):
    if end_date < start_date:
        raise HTTPException(status_code=400, detail="end_date must be >= start_date")
    if (end_date - start_date).days > 365:
        raise HTTPException(status_code=400, detail="Date range cannot exceed 365 days")

    stats = await step_service.get_step_stats(db, user.id, start_date, end_date)
    return SuccessResponse(data=stats)


@router.get(
    "/trend",
    response_model=SuccessResponse[StepTrend],
    summary="Compare current period vs previous period",
)
async def get_trend(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
    days: int = Query(default=7, ge=1, le=90, description="Period length in days"),
):
    today = date.today()
    current_start = today - timedelta(days=days - 1)
    previous_start = current_start - timedelta(days=days)
    previous_end = current_start - timedelta(days=1)

    trend = await step_service.get_step_trend(
        db, user.id, current_start, today, previous_start, previous_end
    )
    return SuccessResponse(data=trend)


@router.get(
    "/history",
    response_model=CursorPage[DailyStepSummaryResponse],
    summary="Get paginated step history",
)
async def get_history(
    user: CurrentUser,
    pagination: Pagination,
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import text

    offset = int(pagination.cursor) if pagination.cursor else 0
    result = await db.execute(
        text("""
            SELECT date, total_steps, total_distance, total_calories,
                   active_minutes, peak_step_hour, sources
            FROM daily_step_summaries
            WHERE user_id = :uid
            ORDER BY date DESC
            LIMIT :limit OFFSET :offset
        """),
        {"uid": str(user.id), "limit": pagination.limit + 1, "offset": offset},
    )
    rows = result.fetchall()
    has_more = len(rows) > pagination.limit
    items = rows[: pagination.limit]

    return CursorPage(
        items=[
            DailyStepSummaryResponse(
                date=r.date,
                total_steps=r.total_steps,
                total_distance=float(r.total_distance),
                total_calories=float(r.total_calories),
                active_minutes=r.active_minutes,
                peak_step_hour=r.peak_step_hour,
                sources=r.sources or [],
            )
            for r in items
        ],
        next_cursor=str(offset + pagination.limit) if has_more else None,
        has_more=has_more,
    )
