"""Auth endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register(client: AsyncClient):
    response = await client.post("/api/v1/auth/register", json={
        "email": "newuser@test.com",
        "password": "securepass123",
        "display_name": "New User",
    })
    assert response.status_code == 201
    data = response.json()["data"]
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate(client: AsyncClient):
    await client.post("/api/v1/auth/register", json={
        "email": "dup@test.com",
        "password": "pass12345",
        "display_name": "Dup",
    })
    response = await client.post("/api/v1/auth/register", json={
        "email": "dup@test.com",
        "password": "pass12345",
        "display_name": "Dup2",
    })
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login(client: AsyncClient):
    await client.post("/api/v1/auth/register", json={
        "email": "login@test.com",
        "password": "mypassword",
        "display_name": "Login User",
    })
    response = await client.post("/api/v1/auth/login", json={
        "email": "login@test.com",
        "password": "mypassword",
    })
    assert response.status_code == 200
    assert "access_token" in response.json()["data"]


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    await client.post("/api/v1/auth/register", json={
        "email": "wrong@test.com",
        "password": "correctpass",
        "display_name": "Wrong",
    })
    response = await client.post("/api/v1/auth/login", json={
        "email": "wrong@test.com",
        "password": "wrongpass",
    })
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient, test_user: dict):
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {test_user['token']}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == test_user["email"]


@pytest.mark.asyncio
async def test_get_me_unauthorized(client: AsyncClient):
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 403
