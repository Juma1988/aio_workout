"""Test configuration and fixtures."""

import asyncio
from typing import AsyncGenerator
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.database import Base, get_db
from app.main import app
from app.services.auth_service import create_access_token, hash_password

# Use a test database URL (override via env or use SQLite for simplicity)
TEST_DATABASE_URL = "postgresql+asyncpg://aio_workout:secret@localhost:5432/aio_workout_test"

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> dict:
    """Create a test user and return credentials."""
    from app.models.user import User

    email = f"test-{uuid4().hex[:8]}@test.com"
    user = User(
        email=email,
        password_hash=hash_password("testpass123"),
        display_name="Test User",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return {
        "id": str(user.id),
        "email": email,
        "password": "testpass123",
        "token": create_access_token(str(user.id)),
    }


@pytest_asyncio.fixture
async def auth_headers(test_user: dict) -> dict:
    return {"Authorization": f"Bearer {test_user['token']}"}
