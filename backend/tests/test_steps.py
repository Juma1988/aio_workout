"""Step endpoint tests."""

from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_sync_steps(client: AsyncClient, auth_headers: dict):
    now = datetime.now(timezone.utc)
    response = await client.post(
        "/api/v1/steps/sync",
        json={
            "device_id": None,
            "records": [
                {
                    "recorded_at": now.isoformat(),
                    "bucket_minutes": 60,
                    "step_count": 500,
                    "distance_meters": 381.0,
                    "calories": 20.0,
                    "source": "phone",
                },
            ],
        },
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["synced"] == 1
    assert data["duplicates_skipped"] == 0


@pytest.mark.asyncio
async def test_get_today(client: AsyncClient, auth_headers: dict):
    response = await client.get(
        "/api/v1/steps/today",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["total_steps"] >= 0


@pytest.mark.asyncio
async def test_step_sync_deduplication(client: AsyncClient, auth_headers: dict):
    now = datetime.now(timezone.utc)
    record = {
        "recorded_at": now.isoformat(),
        "bucket_minutes": 60,
        "step_count": 100,
        "source": "phone",
    }

    # First sync
    resp1 = await client.post(
        "/api/v1/steps/sync",
        json={"records": [record]},
        headers=auth_headers,
    )
    assert resp1.json()["data"]["synced"] == 1

    # Duplicate sync
    resp2 = await client.post(
        "/api/v1/steps/sync",
        json={"records": [record]},
        headers=auth_headers,
    )
    assert resp2.json()["data"]["duplicates_skipped"] == 1
    assert resp2.json()["data"]["synced"] == 0


@pytest.mark.asyncio
async def test_get_stats(client: AsyncClient, auth_headers: dict):
    today = datetime.now(timezone.utc).date()
    week_ago = today - timedelta(days=7)
    response = await client.get(
        f"/api/v1/steps/stats?start_date={week_ago}&end_date={today}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    stats = response.json()["data"]
    assert "total_steps" in stats
    assert "average_steps" in stats


@pytest.mark.asyncio
async def test_step_history_pagination(client: AsyncClient, auth_headers: dict):
    response = await client.get(
        "/api/v1/steps/history?limit=10",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert "items" in data
    assert "has_more" in data
