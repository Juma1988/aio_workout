"""Background task: check and unlock achievements after data sync."""

from datetime import date, datetime, timezone

from sqlalchemy import text

from app.database import AsyncSessionLocal
from app.services.notification_service import (
    get_user_push_tokens,
    log_notification,
    send_push_notification,
)


async def check_and_unlock_achievements(user_id: str):
    """Evaluate all achievement definitions for a user and unlock any newly met."""
    async with AsyncSessionLocal() as db:
        # Get user stats
        stats = await _get_user_stats(db, user_id)

        # Get all definitions
        defs_result = await db.execute(
            text("SELECT * FROM achievement_definitions ORDER BY sort_order")
        )
        definitions = defs_result.fetchall()

        newly_unlocked = []

        for defn in definitions:
            # Check if already unlocked
            existing = await db.execute(
                text("""
                    SELECT id, progress FROM user_achievements
                    WHERE user_id = :uid AND achievement_id = :aid
                """),
                {"uid": user_id, "aid": defn.id},
            )
            existing_row = existing.first()

            progress = _compute_progress(defn, stats)
            is_complete = progress >= defn.threshold_value

            if existing_row:
                # Update progress
                await db.execute(
                    text("""
                        UPDATE user_achievements
                        SET progress = :progress,
                            unlocked_at = CASE
                                WHEN :complete AND unlocked_at IS NULL THEN NOW()
                                ELSE unlocked_at
                            END
                        WHERE user_id = :uid AND achievement_id = :aid
                    """),
                    {"uid": user_id, "aid": defn.id, "progress": progress, "complete": is_complete},
                )
                if is_complete and not existing_row.progress:
                    newly_unlocked.append(defn)
            else:
                # Create new entry
                await db.execute(
                    text("""
                        INSERT INTO user_achievements (id, user_id, achievement_id, progress, unlocked_at)
                        VALUES (:id, :uid, :aid, :progress, CASE WHEN :complete THEN NOW() ELSE NULL END)
                    """),
                    {
                        "id": str(__import__('uuid').uuid4()),
                        "uid": user_id,
                        "aid": defn.id,
                        "progress": progress,
                        "complete": is_complete,
                    },
                )
                if is_complete:
                    newly_unlocked.append(defn)

        await db.commit()

        # Send notifications for newly unlocked
        if newly_unlocked:
            tokens = await get_user_push_tokens(db, __import__('uuid').UUID(user_id))
            if tokens:
                titles = [a.title for a in newly_unlocked[:3]]
                body = f"Achievement unlocked: {', '.join(titles)}!"
                await send_push_notification(tokens, "Achievement Unlocked! 🏆", body)
                await log_notification(
                    db, __import__('uuid').UUID(user_id),
                    "achievement", "Achievement Unlocked!", body,
                )

        return {"newly_unlocked": len(newly_unlocked)}


async def _get_user_stats(db, user_id: str) -> dict:
    """Gather all stats needed for achievement evaluation."""
    # Total workouts
    r = await db.execute(
        text("SELECT COUNT(*) FROM workout_sessions WHERE user_id = :uid AND deleted_at IS NULL"),
        {"uid": user_id},
    )
    total_workouts = r.scalar() or 0

    # Total sets
    r = await db.execute(
        text("""
            SELECT COALESCE(SUM(ce.sets_completed), 0)
            FROM completed_exercises ce
            JOIN workout_sessions ws ON ws.id = ce.session_id
            WHERE ws.user_id = :uid AND ws.deleted_at IS NULL
        """),
        {"uid": user_id},
    )
    total_sets = r.scalar() or 0

    # Completed weeks
    r = await db.execute(
        text("SELECT COUNT(DISTINCT week_number) FROM workout_sessions WHERE user_id = :uid AND deleted_at IS NULL"),
        {"uid": user_id},
    )
    completed_weeks = r.scalar() or 0

    # Total steps (all time)
    r = await db.execute(
        text("SELECT COALESCE(SUM(total_steps), 0) FROM daily_step_summaries WHERE user_id = :uid"),
        {"uid": user_id},
    )
    total_steps = r.scalar() or 0

    # Current step streak
    r = await db.execute(
        text("""
            SELECT date, total_steps FROM daily_step_summaries
            WHERE user_id = :uid
            ORDER BY date DESC
            LIMIT 100
        """),
        {"uid": user_id},
    )
    streak = 0
    today = date.today()
    for row in r.fetchall():
        if row.date == today - __import__('datetime').timedelta(days=streak):
            if row.total_steps >= 10000:  # Default daily target
                streak += 1
            else:
                break
        else:
            break

    return {
        "total_workouts": total_workouts,
        "total_sets": total_sets,
        "completed_weeks": completed_weeks,
        "total_steps": total_steps,
        "step_streak": streak,
    }


def _compute_progress(defn, stats: dict) -> int:
    mapping = {
        "first_steps": stats["total_workouts"],
        "week_warrior": stats["completed_weeks"],
        "dedicated": stats["completed_weeks"],
        "halfway": stats["completed_weeks"],
        "graduate": stats["completed_weeks"],
        "volume_100": stats["total_sets"],
        "volume_500": stats["total_sets"],
        "streak_5": stats["step_streak"],
    }
    return mapping.get(defn.id, 0)
