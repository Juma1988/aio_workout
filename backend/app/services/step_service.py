"""Step service: sync, query, aggregate, stats."""

from datetime import date, datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.step_record import DailyStepSummary, StepRecord
from app.schemas.steps import (
    DailyStepSummaryResponse,
    StepRecordInput,
    StepSyncResponse,
    StepStats,
    StepTrend,
)


async def sync_steps(
    db: AsyncSession,
    user_id: UUID,
    device_id: str | None,
    records: list[StepRecordInput],
) -> StepSyncResponse:
    """Bulk upsert step records. Deduplicates by (user_id, recorded_at, source)."""
    synced = 0
    duplicates = 0

    for rec in records:
        # Check for duplicate (same user + timestamp + source)
        existing = await db.execute(
            text("""
                SELECT id FROM step_records
                WHERE user_id = :uid AND recorded_at = :ts AND source = :source
                LIMIT 1
            """),
            {"uid": str(user_id), "ts": rec.recorded_at, "source": rec.source},
        )
        if existing.first():
            duplicates += 1
            continue

        step = StepRecord(
            user_id=user_id,
            device_id=UUID(device_id) if device_id else None,
            recorded_at=rec.recorded_at,
            bucket_minutes=rec.bucket_minutes,
            step_count=rec.step_count,
            distance_meters=rec.distance_meters,
            calories=rec.calories,
            source=rec.source,
            metadata_=rec.metadata,
        )
        db.add(step)
        synced += 1

    await db.flush()

    # Update daily summary
    if synced > 0:
        summary_date = records[0].recorded_at.date()
        total_steps = sum(r.step_count for r in records)
        total_distance = sum(r.distance_meters or 0 for r in records)
        total_calories = sum(r.calories or 0 for r in records)
        sources = list({r.source for r in records})

        await db.execute(
            text("""
                SELECT upsert_daily_step_summary(
                    :user_id, :date, :steps, :distance, :calories, 0, :source
                )
            """),
            {
                "user_id": str(user_id),
                "date": summary_date,
                "steps": total_steps,
                "distance": total_distance,
                "calories": total_calories,
                "source": sources[0] if sources else "phone",
            },
        )

    return StepSyncResponse(
        synced=synced,
        duplicates_skipped=duplicates,
        summary_date=records[0].recorded_at.date() if records else date.today(),
    )


async def get_daily_summary(
    db: AsyncSession,
    user_id: UUID,
    target_date: date,
) -> DailyStepSummaryResponse | None:
    result = await db.execute(
        text("""
            SELECT date, total_steps, total_distance, total_calories,
                   active_minutes, peak_step_hour, sources
            FROM daily_step_summaries
            WHERE user_id = :user_id AND date = :date
        """),
        {"user_id": str(user_id), "date": target_date},
    )
    row = result.first()
    if not row:
        return DailyStepSummaryResponse(
            date=target_date, total_steps=0, total_distance=0,
            total_calories=0, active_minutes=0, peak_step_hour=None, sources=[],
        )
    return DailyStepSummaryResponse(
        date=row.date,
        total_steps=row.total_steps,
        total_distance=float(row.total_distance),
        total_calories=float(row.total_calories),
        active_minutes=row.active_minutes,
        peak_step_hour=row.peak_step_hour,
        sources=row.sources or [],
    )


async def get_step_stats(
    db: AsyncSession,
    user_id: UUID,
    start_date: date,
    end_date: date,
    period: str = "daily",
) -> StepStats:
    result = await db.execute(
        text("""
            SELECT date, total_steps, total_distance, total_calories,
                   active_minutes, peak_step_hour, sources
            FROM daily_step_summaries
            WHERE user_id = :user_id
              AND date BETWEEN :start AND :end
            ORDER BY date ASC
        """),
        {"user_id": str(user_id), "start": start_date, "end": end_date},
    )
    rows = result.fetchall()

    summaries = [
        DailyStepSummaryResponse(
            date=r.date,
            total_steps=r.total_steps,
            total_distance=float(r.total_distance),
            total_calories=float(r.total_calories),
            active_minutes=r.active_minutes,
            peak_step_hour=r.peak_step_hour,
            sources=r.sources or [],
        )
        for r in rows
    ]

    steps_list = [s.total_steps for s in summaries] or [0]

    return StepStats(
        period=period,
        start_date=start_date,
        end_date=end_date,
        total_steps=sum(steps_list),
        average_steps=sum(steps_list) / len(steps_list),
        max_steps=max(steps_list),
        min_steps=min(steps_list),
        total_distance=sum(s.total_distance for s in summaries),
        total_calories=sum(s.total_calories for s in summaries),
        days_with_data=len([s for s in summaries if s.total_steps > 0]),
        daily_breakdown=summaries,
    )


async def get_step_trend(
    db: AsyncSession,
    user_id: UUID,
    current_start: date,
    current_end: date,
    previous_start: date,
    previous_end: date,
) -> StepTrend:
    current_stats = await get_step_stats(db, user_id, current_start, current_end)
    previous_stats = await get_step_stats(db, user_id, previous_start, previous_end)

    current_avg = current_stats.average_steps
    previous_avg = previous_stats.average_steps

    if previous_avg == 0:
        change_pct = 100.0 if current_avg > 0 else 0.0
    else:
        change_pct = ((current_avg - previous_avg) / previous_avg) * 100

    if change_pct > 5:
        trend = "up"
    elif change_pct < -5:
        trend = "down"
    else:
        trend = "stable"

    return StepTrend(
        current_period_avg=current_avg,
        previous_period_avg=previous_avg,
        change_percent=round(change_pct, 1),
        trend=trend,
    )
