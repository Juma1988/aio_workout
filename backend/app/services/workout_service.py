"""Workout service: sync from device, query history."""

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.workout import CompletedExercise, WorkoutSession
from app.schemas.workouts import (
    CompletedExerciseInput,
    CompletedExerciseResponse,
    WorkoutHistory,
    WorkoutSessionInput,
    WorkoutSessionResponse,
)


async def sync_workout(
    db: AsyncSession,
    user_id: UUID,
    data: WorkoutSessionInput,
    device_id: str | None = None,
) -> WorkoutSessionResponse:
    """Create a workout session from device sync."""
    session = WorkoutSession(
        user_id=user_id,
        session_date=data.session_date,
        week_number=data.week_number,
        day_number=data.day_number,
        focus=data.focus,
        duration_seconds=data.duration_seconds,
        steps_during=data.steps_during,
        hydration_liters=data.hydration_liters,
        notes=data.notes,
        synced_from_device=True,
        device_id=UUID(device_id) if device_id else None,
    )
    db.add(session)
    await db.flush()

    exercises = []
    for ex_data in data.exercises:
        ex = CompletedExercise(
            session_id=session.id,
            exercise_uuid=ex_data.exercise_uuid,
            exercise_name=ex_data.exercise_name,
            sets_completed=ex_data.sets_completed,
            reps_completed=ex_data.reps_completed,
            duration_seconds=ex_data.duration_seconds,
            weight_kg=ex_data.weight_kg,
            notes=ex_data.notes,
        )
        db.add(ex)
        exercises.append(ex)

    await db.flush()

    return WorkoutSessionResponse(
        id=session.id,
        session_date=session.session_date,
        week_number=session.week_number,
        day_number=session.day_number,
        focus=session.focus,
        duration_seconds=session.duration_seconds,
        steps_during=session.steps_during,
        hydration_liters=float(session.hydration_liters),
        exercises=[CompletedExerciseResponse.model_validate(e) for e in exercises],
        notes=session.notes,
        created_at=session.created_at,
    )


async def get_workout_history(
    db: AsyncSession,
    user_id: UUID,
    limit: int = 50,
    offset: int = 0,
) -> WorkoutHistory:
    # Fetch sessions
    result = await db.execute(
        text("""
            SELECT id, session_date, week_number, day_number, focus,
                   duration_seconds, steps_during, hydration_liters, notes, created_at
            FROM workout_sessions
            WHERE user_id = :uid AND deleted_at IS NULL
            ORDER BY session_date DESC
            LIMIT :limit OFFSET :offset
        """),
        {"uid": str(user_id), "limit": limit, "offset": offset},
    )
    sessions = []
    total_sets = 0
    total_duration = 0
    for row in result.fetchall():
        # Fetch exercises for this session
        ex_result = await db.execute(
            text("""
                SELECT id, exercise_uuid, exercise_name, sets_completed,
                       reps_completed, duration_seconds, weight_kg, notes
                FROM completed_exercises
                WHERE session_id = :sid
            """),
            {"sid": str(row.id)},
        )
        exercises = [
            CompletedExerciseResponse(
                id=er.id,
                exercise_uuid=er.exercise_uuid,
                exercise_name=er.exercise_name,
                sets_completed=er.sets_completed,
                reps_completed=er.reps_completed,
                duration_seconds=er.duration_seconds,
                weight_kg=float(er.weight_kg) if er.weight_kg else None,
                notes=er.notes or "",
            )
            for er in ex_result.fetchall()
        ]
        session_sets = sum(e.sets_completed for e in exercises)
        total_sets += session_sets
        total_duration += row.duration_seconds

        sessions.append(WorkoutSessionResponse(
            id=row.id,
            session_date=row.session_date,
            week_number=row.week_number,
            day_number=row.day_number,
            focus=row.focus,
            duration_seconds=row.duration_seconds,
            steps_during=row.steps_during,
            hydration_liters=float(row.hydration_liters),
            exercises=exercises,
            notes=row.notes,
            created_at=row.created_at,
        ))

    # Count totals
    count_result = await db.execute(
        text("""
            SELECT COUNT(*) FROM workout_sessions
            WHERE user_id = :uid AND deleted_at IS NULL
        """),
        {"uid": str(user_id)},
    )
    total_workouts = count_result.scalar() or 0

    # Streak calculation
    streak_result = await db.execute(
        text("""
            SELECT DISTINCT DATE(session_date) as d
            FROM workout_sessions
            WHERE user_id = :uid AND deleted_at IS NULL
            ORDER BY d DESC
        """),
        {"uid": str(user_id)},
    )
    dates = [r.d for r in streak_result.fetchall()]
    current_streak = _calculate_streak(dates)
    longest_streak = _calculate_longest_streak(dates)

    # Completed weeks
    week_result = await db.execute(
        text("""
            SELECT COUNT(DISTINCT week_number) as weeks
            FROM workout_sessions
            WHERE user_id = :uid AND deleted_at IS NULL
        """),
        {"uid": str(user_id)},
    )
    completed_weeks = week_result.scalar() or 0

    return WorkoutHistory(
        sessions=sessions,
        total_workouts=total_workouts,
        total_sets=total_sets,
        total_duration_seconds=total_duration,
        current_streak=current_streak,
        longest_streak=longest_streak,
        completed_weeks=completed_weeks,
    )


def _calculate_streak(dates: list) -> int:
    if not dates:
        return 0
    streak = 1
    for i in range(len(dates) - 1):
        diff = (dates[i] - dates[i + 1]).days
        if diff <= 2:
            streak += 1
        else:
            break
    return streak


def _calculate_longest_streak(dates: list) -> int:
    if not dates:
        return 0
    longest = 1
    current = 1
    for i in range(len(dates) - 1):
        diff = (dates[i] - dates[i + 1]).days
        if diff <= 2:
            current += 1
            longest = max(longest, current)
        else:
            current = 1
    return longest
