# AIO Workout Backend

A FastAPI backend for the AIO Workout mobile app — step tracking, workouts, goals, and social features.

## Quick Start

```bash
# Copy environment template
cp .env.example .env

# Start everything with Docker
docker compose up -d

# Run migrations
docker compose exec api alembic upgrade head

# Seed demo data
docker compose exec api python -m app.scripts.seed_data

# API docs
open http://localhost:8000/docs
```

## Development

```bash
# Install dependencies
pip install -r requirements/dev.txt

# Start PostgreSQL + Redis only
docker compose up -d postgres redis

# Run the API with hot-reload
uvicorn app.main:app --reload --port 8000

# Run tests
pytest -x --cov=app

# Type checking
mypy app

# Linting
ruff check app
```

## Project Structure

```
backend/
├── alembic/                    # DB migrations
│   └── versions/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── config.py               # Settings via pydantic-settings
│   ├── database.py             # SQLAlchemy async engine + session
│   ├── dependencies.py         # Common DI (get_db, get_current_user)
│   │
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── user.py
│   │   ├── device.py
│   │   ├── step_record.py
│   │   ├── step_goal.py
│   │   ├── workout.py
│   │   ├── weight.py
│   │   ├── achievement.py
│   │   ├── social.py
│   │   └── notification.py
│   │
│   ├── schemas/                # Pydantic request/response DTOs
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── steps.py
│   │   ├── goals.py
│   │   ├── workouts.py
│   │   ├── weight.py
│   │   ├── achievements.py
│   │   ├── social.py
│   │   ├── notifications.py
│   │   └── common.py           # Pagination, error responses
│   │
│   ├── services/               # Business logic
│   │   ├── auth_service.py
│   │   ├── step_service.py
│   │   ├── workout_service.py
│   │   ├── goal_service.py
│   │   ├── analytics_service.py
│   │   ├── achievement_service.py
│   │   ├── social_service.py
│   │   ├── notification_service.py
│   │   └── device_service.py
│   │
│   ├── api/                    # Route definitions
│   │   ├── v1/
│   │   │   ├── auth.py
│   │   │   ├── steps.py
│   │   │   ├── workouts.py
│   │   │   ├── goals.py
│   │   │   ├── analytics.py
│   │   │   ├── achievements.py
│   │   │   ├── social.py
│   │   │   ├── devices.py
│   │   │   └── notifications.py
│   │   └── router.py           # Mount all v1 routers
│   │
│   ├── tasks/                  # Background jobs (ARQ)
│   │   ├── daily_aggregation.py
│   │   ├── achievement_checker.py
│   │   ├── leaderboard_refresh.py
│   │   └── push_notifications.py
│   │
│   └── scripts/                # One-off scripts
│       └── seed_data.py
│
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_steps.py
│   └── ...
│
├── docker/
│   ├── Dockerfile
│   └── nginx.conf
│
├── docker-compose.yml
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
├── alembic.ini
├── .env.example
└── README.md
```
