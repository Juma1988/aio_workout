"""ARQ worker settings for background tasks."""

from arq import cron
from arq.connections import RedisSettings
from app.config import get_settings

settings = get_settings()


class WorkerSettings:
    functions = [
        "app.tasks.daily_aggregation:aggregate_daily_steps",
        "app.tasks.daily_aggregation:aggregate_last_7_days",
        "app.tasks.achievement_checker:check_and_unlock_achievements",
        "app.tasks.leaderboard_refresh:refresh_leaderboard",
    ]
    cron_jobs = [
        cron(
            "app.tasks.daily_aggregation:aggregate_last_7_days",
            hour=1,
            minute=0,
        ),
        cron(
            "app.tasks.leaderboard_refresh:refresh_leaderboard",
            hour=0,
            minute=30,
            kwargs={"period_type": "weekly"},
        ),
    ]
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL)
    max_jobs = 10
    job_timeout = 300
    keep_result = 3600
