"""V1 API router — mounts all endpoint modules."""

from fastapi import APIRouter

from app.api.v1 import (
    auth,
    steps,
    workouts,
    goals,
    analytics,
    achievements,
    social,
    devices,
    notifications,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(steps.router, prefix="/steps", tags=["Step Tracking"])
api_router.include_router(workouts.router, prefix="/workouts", tags=["Workouts"])
api_router.include_router(goals.router, prefix="/goals", tags=["Goals"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
api_router.include_router(achievements.router, prefix="/achievements", tags=["Achievements"])
api_router.include_router(social.router, prefix="/social", tags=["Social"])
api_router.include_router(devices.router, prefix="/devices", tags=["Devices"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
