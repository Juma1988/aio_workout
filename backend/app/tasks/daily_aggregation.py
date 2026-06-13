"""Background task: daily step aggregation.

Run nightly via ARQ worker to update daily_step_summaries from raw step_records.
This pre-computation makes the UI fast.
"""

import asyncio
from datetime import date, timedelta

from sqlalchemy import text

from app.database import AsyncSessionLocal


async def aggregate_daily_steps(target_date: date | None = None):
    """Aggregate raw step_records into daily_step_summaries for the given date.

    If no date given, aggregates yesterday.
    """
    if target_date is None:
        target_date = date.today() - timedelta(days=1)

    async with AsyncSessionLocal() as db:
        # Get all users who had step records on this date
        result = await db.execute(
            text("""
                SELECT DISTINCT user_id
                FROM step_records
                WHERE DATE(recorded_at) = :target
            """),
            {"target": target_date},
        )
        user_ids = [r.user_id for r in result.fetchall()]

        for uid in user_ids:
            # Aggregate from raw records
            agg_result = await db.execute(
                text("""
                    SELECT
                        SUM(step_count) as total_steps,
                        COALESCE(SUM(distance_meters), 0) as total_distance,
                        COALESCE(SUM(calories), 0) as total_calories,
                        COUNT(*) as data_points,
                        array_agg(DISTINCT source) as sources,
                        MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM recorded_at)) as peak_hour
                    FROM step_records
                    WHERE user_id = :uid
                      AND DATE(recorded_at) = :target
                """),
                {"uid": str(uid), "target": target_date},
            )
            agg = agg_result.first()
            if not agg or not agg.total_steps:
                continue

            # Calculate active minutes (buckets where steps > 0)
            active_result = await db.execute(
                text("""
                    SELECT COUNT(DISTINCT DATE_TRUNC('minute', recorded_at))
                    FROM step_records
                    WHERE user_id = :uid
                      AND DATE(recorded_at) = :target
                      AND step_count > 0
                """),
                {"uid": str(uid), "target": target_date},
            )
            active_minutes = active_result.scalar() or 0

            # Upsert daily summary
            await db.execute(
                text("""
                    INSERT INTO daily_step_summaries
                        (user_id, date, total_steps, total_distance, total_calories,
                         active_minutes, peak_step_hour, data_points, sources)
                    VALUES (:uid, :date, :steps, :dist, :cal, :active, :peak, :dp, :sources)
                    ON CONFLICT (user_id, date) DO UPDATE SET
                        total_steps = EXCLUDED.total_steps,
                        total_distance = EXCLUDED.total_distance,
                        total_calories = EXCLUDED.total_calories,
                        active_minutes = EXCLUDED.active_minutes,
                        peak_step_hour = EXCLUDED.peak_step_hour,
                        data_points = EXCLUDED.data_points,
                        sources = EXCLUDED.sources,
                        updated_at = NOW()
                """),
                {
                    "uid": str(uid),
                    "date": target_date,
                    "steps": agg.total_steps,
                    "dist": float(agg.total_distance),
                    "cal": float(agg.total_calories),
                    "active": active_minutes,
                    "peak": agg.peak_hour,
                    "dp": agg.data_points,
                    "sources": agg.sources,
                },
            )

        await db.commit()
        return {"aggregated_users": len(user_ids), "date": str(target_date)}


async def aggregate_last_7_days():
    """Aggregate the last 7 days (catch-up job)."""
    today = date.today()
    results = []
    for i in range(7):
        d = today - timedelta(days=i)
        result = await aggregate_daily_steps(d)
        results.append(result)
    return results


if __name__ == "__main__":
    asyncio.run(aggregate_daily_steps())
