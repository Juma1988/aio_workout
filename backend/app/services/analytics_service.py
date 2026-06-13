"""Analytics service: aggregated insights, trends."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.steps import HourlyDistribution, StepStats


async def get_hourly_distribution(
    db: AsyncSession,
    user_id: UUID,
    target_date: date,
) -> list[HourlyDistribution]:
    """Get average steps per hour of day (for heatmap/calendar views)."""
    result = await db.execute(
        text("""
            SELECT
                EXTRACT(HOUR FROM recorded_at)::int as hour,
                SUM(step_count) as total_steps,
                COUNT(DISTINCT DATE(recorded_at)) as day_count
            FROM step_records
            WHERE user_id = :uid
              AND recorded_at >= :start
              AND recorded_at < :end
            GROUP BY hour
            ORDER BY hour
        """),
        {
            "uid": str(user_id),
            "start": target_date - timedelta(days=30),
            "end": target_date + timedelta(days=1),
        },
    )

    hourly = {}
    for row in result.fetchall():
        avg = row.total_steps / max(row.day_count, 1)
        hourly[row.hour] = HourlyDistribution(hour=row.hour, avg_steps=round(avg, 1))

    return [hourly.get(h, HourlyDistribution(hour=h, avg_steps=0)) for h in range(24)]


async def get_weekly_comparison(
    db: AsyncSession,
    user_id: UUID,
) -> dict:
    """Compare this week vs last week."""
    today = date.today()
    this_week_start = today - timedelta(days=today.weekday())
    last_week_start = this_week_start - timedelta(days=7)

    result = await db.execute(
        text("""
            SELECT
                CASE
                    WHEN date >= :this_week THEN 'this_week'
                    ELSE 'last_week'
                END as period,
                SUM(total_steps) as steps,
                SUM(total_distance) as distance,
                SUM(total_calories) as calories,
                COUNT(*) as days
            FROM daily_step_summaries
            WHERE user_id = :uid
              AND date >= :last_week
              AND date <= :today
            GROUP BY period
        """),
        {
            "uid": str(user_id),
            "this_week": this_week_start,
            "last_week": last_week_start,
            "today": today,
        },
    )

    data = {}
    for row in result.fetchall():
        data[row.period] = {
            "steps": row.steps or 0,
            "distance": float(row.distance or 0),
            "calories": float(row.calories or 0),
            "days": row.days,
        }

    this = data.get("this_week", {"steps": 0, "distance": 0, "calories": 0, "days": 0})
    last = data.get("last_week", {"steps": 0, "distance": 0, "calories": 0, "days": 0})

    return {
        "this_week": this,
        "last_week": last,
        "steps_change": this["steps"] - last["steps"],
        "steps_change_percent": (
            round(((this["steps"] - last["steps"]) / max(last["steps"], 1)) * 100, 1)
            if last["steps"] > 0
            else 0
        ),
    }


async def get_monthly_heatmap(
    db: AsyncSession,
    user_id: UUID,
    year: int,
    month: int,
) -> list[dict]:
    """Get daily step totals for a month (for calendar heatmap)."""
    result = await db.execute(
        text("""
            SELECT date, total_steps
            FROM daily_step_summaries
            WHERE user_id = :uid
              AND EXTRACT(YEAR FROM date) = :year
              AND EXTRACT(MONTH FROM date) = :month
            ORDER BY date
        """),
        {"uid": str(user_id), "year": year, "month": month},
    )

    return [
        {"date": str(r.date), "steps": r.total_steps}
        for r in result.fetchall()
    ]
