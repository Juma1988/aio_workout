"""Seed database with achievement definitions and demo data."""

import asyncio
from datetime import date, datetime, timedelta, timezone
import random

from sqlalchemy import text

from app.database import AsyncSessionLocal
from app.services.auth_service import hash_password

ACHIEVEMENTS = [
    ("first_steps", "First Steps", "Complete your first workout", "fitness_center", "workout", "bronze", 1, "count", 1),
    ("week_warrior", "Week Warrior", "Complete a full week (5 workouts)", "shield", "workout", "silver", 5, "count", 2),
    ("dedicated", "Dedicated", "Complete 4 consecutive weeks", "star", "streak", "gold", 4, "count", 3),
    ("halfway", "Halfway There", "Complete 6 weeks", "trending_up", "workout", "gold", 6, "count", 4),
    ("graduate", "Program Graduate", "Complete all 12 weeks", "school", "workout", "platinum", 12, "count", 5),
    ("core_crusher", "Core Crusher", "Complete 10 core workouts", "fitness_center", "workout", "silver", 10, "count", 6),
    ("upper_champ", "Upper Body Champ", "Complete 10 upper body workouts", "sports_martial_arts", "workout", "silver", 10, "count", 7),
    ("lower_legend", "Lower Body Legend", "Complete 10 lower body workouts", "directions_walk", "workout", "silver", 10, "count", 8),
    ("full_fusion", "Full Body Fusion", "Complete 10 full body workouts", "whatshot", "workout", "silver", 10, "count", 9),
    ("volume_100", "Volume 100", "Complete 100 total exercise sets", "looks_one", "workout", "gold", 100, "count", 10),
    ("volume_500", "Volume 500", "Complete 500 total exercise sets", "looks_two", "workout", "platinum", 500, "count", 11),
    ("streak_5", "Streak Master", "5-day step streak at 10k+", "local_fire_department", "steps", "bronze", 5, "streak_days", 12),
    ("streak_14", "Two-Week Warrior", "14-day step streak at 10k+", "local_fire_department", "steps", "silver", 14, "streak_days", 13),
    ("streak_30", "Monthly Machine", "30-day step streak at 10k+", "local_fire_department", "steps", "gold", 30, "streak_days", 14),
    ("step_100k", "Century Walker", "Walk 100,000 total steps", "directions_walk", "steps", "bronze", 100000, "total_value", 15),
    ("step_1m", "Million Stepper", "Walk 1,000,000 total steps", "emoji_events", "steps", "gold", 1000000, "total_value", 16),
    ("step_50k_week", "Weekly Champion", "Walk 50,000+ steps in a week", "emoji_events", "steps", "silver", 50000, "total_value", 17),
    ("weight_goal", "Goal Crusher", "Reach your target weight", "monitor_weight", "weight", "gold", 1, "boolean", 18),
    ("social_butterfly", "Social Butterfly", "Add 5 friends", "group", "social", "bronze", 5, "count", 19),
    ("challenge_accepted", "Challenge Accepted", "Complete your first challenge", "flag", "social", "silver", 1, "count", 20),
]


async def seed():
    async with AsyncSessionLocal() as db:
        # Achievement definitions
        for a in ACHIEVEMENTS:
            await db.execute(
                text("""
                    INSERT INTO achievement_definitions
                        (id, title, description, icon_name, category, tier,
                         threshold_value, threshold_type, sort_order)
                    VALUES (:id, :title, :desc, :icon, :cat, :tier, :val, :type, :sort)
                    ON CONFLICT (id) DO NOTHING
                """),
                {
                    "id": a[0], "title": a[1], "desc": a[2], "icon": a[3],
                    "cat": a[4], "tier": a[5], "val": a[6], "type": a[7], "sort": a[8],
                },
            )

        # Demo user
        demo_email = "demo@aio-workout.dev"
        existing = await db.execute(
            text("SELECT id FROM users WHERE email = :email"),
            {"email": demo_email},
        )
        if not existing.first():
            from uuid import uuid4
            user_id = uuid4()
            await db.execute(
                text("""
                    INSERT INTO users (id, email, password_hash, display_name, gender, height_cm, weight_kg)
                    VALUES (:id, :email, :pw, :name, :gender, :height, :weight)
                """),
                {
                    "id": str(user_id),
                    "email": demo_email,
                    "pw": hash_password("demo1234"),
                    "name": "Demo User",
                    "gender": "male",
                    "height": 175.0,
                    "weight": 70.0,
                },
            )

            # Seed 30 days of step data
            today = date.today()
            for i in range(30):
                d = today - timedelta(days=i)
                steps = random.randint(3000, 15000)
                distance = steps * 0.762  # avg stride
                calories = steps * 0.04
                await db.execute(
                    text("""
                        INSERT INTO daily_step_summaries (user_id, date, total_steps, total_distance, total_calories, active_minutes, sources)
                        VALUES (:uid, :date, :steps, :dist, :cal, :active, :sources)
                        ON CONFLICT (user_id, date) DO NOTHING
                    """),
                    {
                        "id": str(uuid4()),
                        "uid": str(user_id),
                        "date": d,
                        "steps": steps,
                        "dist": round(distance, 2),
                        "cal": round(calories, 1),
                        "active": steps // 100,
                        "sources": ["phone"],
                    },
                )

            # Set daily goal
            await db.execute(
                text("""
                    INSERT INTO step_goals (id, user_id, goal_type, target_steps, start_date)
                    VALUES (:id, :uid, 'daily', 10000, :start)
                """),
                {"id": str(uuid4()), "uid": str(user_id), "start": today - timedelta(days=30)},
            )

            print(f"Seeded demo user: {demo_email} (password: demo1234)")
            print(f"  - 30 days of step data")
            print(f"  - Daily goal: 10,000 steps")
            print(f"  - {len(ACHIEVEMENTS)} achievement definitions")

        await db.commit()
        print("Seed complete!")


if __name__ == "__main__":
    asyncio.run(seed())
