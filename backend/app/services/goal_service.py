"""Goal service: CRUD, progress tracking."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.step_goal import StepGoal
from app.schemas.goals import (
    GoalCreate,
    GoalHistory,
    GoalProgress,
    GoalResponse,
    GoalUpdate,
)


async def create_goal(db: AsyncSession, user_id: UUID, data: GoalCreate) -> GoalResponse:
    goal = StepGoal(
        user_id=user_id,
        goal_type=data.goal_type,
        target_steps=data.target_steps,
        start_date=data.start_date,
        end_date=data.end_date,
    )
    db.add(goal)
    await db.flush()
    return GoalResponse.model_validate(goal)


async def list_goals(
    db: AsyncSession, user_id: UUID, active_only: bool = True
) -> list[GoalResponse]:
    conditions = ["user_id = :uid"]
    if active_only:
        conditions.append("is_active = TRUE")

    result = await db.execute(
        text(f"""
            SELECT id, goal_type, target_steps, start_date, end_date,
                   is_active, created_at
            FROM step_goals
            WHERE {' AND '.join(conditions)}
            ORDER BY created_at DESC
        """),
        {"uid": str(user_id)},
    )
    return [
        GoalResponse(
            id=row.id,
            goal_type=row.goal_type,
            target_steps=row.target_steps,
            start_date=row.start_date,
            end_date=row.end_date,
            is_active=row.is_active,
            created_at=row.created_at,
        )
        for row in result.fetchall()
    ]


async def update_goal(
    db: AsyncSession, user_id: UUID, goal_id: UUID, data: GoalUpdate
) -> GoalResponse | None:
    updates = []
    params: dict = {"uid": str(user_id), "gid": str(goal_id)}

    if data.target_steps is not None:
        updates.append("target_steps = :target")
        params["target"] = data.target_steps
    if data.end_date is not None:
        updates.append("end_date = :end_date")
        params["end_date"] = data.end_date
    if data.is_active is not None:
        updates.append("is_active = :active")
        params["active"] = data.is_active

    if not updates:
        return None

    result = await db.execute(
        text(f"""
            UPDATE step_goals
            SET {', '.join(updates)}
            WHERE user_id = :uid AND id = :gid
            RETURNING id, goal_type, target_steps, start_date, end_date,
                      is_active, created_at
        """),
        params,
    )
    row = result.first()
    if not row:
        return None
    return GoalResponse(
        id=row.id,
        goal_type=row.goal_type,
        target_steps=row.target_steps,
        start_date=row.start_date,
        end_date=row.end_date,
        is_active=row.is_active,
        created_at=row.created_at,
    )


async def get_goal_progress(
    db: AsyncSession, user_id: UUID, goal_id: UUID
) -> GoalProgress | None:
    goals = await list_goals(db, user_id, active_only=False)
    goal = next((g for g in goals if g.id == goal_id), None)
    if not goal:
        return None

    today = date.today()

    # Get today's steps
    result = await db.execute(
        text("""
            SELECT COALESCE(total_steps, 0)
            FROM daily_step_summaries
            WHERE user_id = :uid AND date = :today
        """),
        {"uid": str(user_id), "today": today},
    )
    current_steps = result.scalar() or 0

    # Calculate streak
    streak = 0
    check_date = today
    while True:
        r = await db.execute(
            text("""
                SELECT total_steps FROM daily_step_summaries
                WHERE user_id = :uid AND date = :d
            """),
            {"uid": str(user_id), "d": check_date},
        )
        row = r.first()
        if row and row.total_steps >= goal.target_steps:
            streak += 1
            check_date -= timedelta(days=1)
        else:
            break

    days_remaining = None
    if goal.end_date:
        days_remaining = max(0, (goal.end_date - today).days)

    progress_pct = (current_steps / goal.target_steps * 100) if goal.target_steps > 0 else 0

    return GoalProgress(
        goal=goal,
        current_steps=current_steps,
        target_steps=goal.target_steps,
        progress_percent=round(min(progress_pct, 100), 1),
        days_remaining=days_remaining,
        is_achieved=current_steps >= goal.target_steps,
        streak_days=streak,
        projected_completion_date=None,
    )
