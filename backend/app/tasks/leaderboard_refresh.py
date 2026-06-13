"""Background task: refresh leaderboard entries."""

from datetime import date, timedelta

from sqlalchemy import text

from app.database import AsyncSessionLocal


async def refresh_leaderboard(period_type: str = "weekly"):
    """Recalculate leaderboard for the given period.

    period_type: 'daily', 'weekly', 'monthly'
    """
    async with AsyncSessionLocal() as db:
        today = date.today()

        if period_type == "daily":
            period_start = today
        elif period_type == "weekly":
            period_start = today - timedelta(days=today.weekday())
        else:  # monthly
            period_start = today.replace(day=1)

        # Calculate total steps per user for the period
        if period_type == "daily":
            date_condition = "date = :period_start"
        elif period_type == "weekly":
            date_condition = "date >= :period_start AND date < :period_start + INTERVAL '7 days'"
        else:
            date_condition = "date >= :period_start AND date < :period_start + INTERVAL '1 month'"

        result = await db.execute(
            text(f"""
                SELECT user_id, SUM(total_steps) as total_steps
                FROM daily_step_summaries
                WHERE {date_condition}
                GROUP BY user_id
                ORDER BY total_steps DESC
            """),
            {"period_start": period_start},
        )

        entries = result.fetchall()

        # Clear existing entries for this period
        await db.execute(
            text("""
                DELETE FROM leaderboard_entries
                WHERE period_type = :pt AND period_start = :ps
            """),
            {"pt": period_type, "ps": period_start},
        )

        # Insert ranked entries
        for rank, entry in enumerate(entries, 1):
            await db.execute(
                text("""
                    INSERT INTO leaderboard_entries (user_id, period_type, period_start, total_steps, rank)
                    VALUES (:uid, :pt, :ps, :steps, :rank)
                """),
                {
                    "uid": str(entry.user_id),
                    "pt": period_type,
                    "ps": period_start,
                    "steps": entry.total_steps,
                    "rank": rank,
                },
            )

        await db.commit()
        return {"period": period_type, "entries": len(entries)}


if __name__ == "__main__":
    import asyncio
    asyncio.run(refresh_leaderboard("weekly"))
