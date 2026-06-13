"""Common FastAPI dependencies: DB session, current user, pagination."""

import uuid
from typing import Annotated

import redis.asyncio as redis
from fastapi import Depends, Header, HTTPException, Query, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.models.user import User

settings = get_settings()
security = HTTPBearer()

# ── Redis client ──
_redis_pool: redis.Redis | None = None


async def get_redis() -> redis.Redis:
    global _redis_pool
    if _redis_pool is None:
        _redis_pool = redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis_pool


# ── Current user from JWT ──
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    if user.deleted_at is not None:
        raise HTTPException(status_code=401, detail="Account deactivated")

    return user


# ── Type aliases ──
CurrentUser = Annotated[User, Depends(get_current_user)]
DBSession = Annotated[AsyncSession, Depends(get_db)]
RedisClient = Annotated[redis.Redis, Depends(get_redis)]


# ── Pagination ──
class PaginationParams:
    def __init__(
        self,
        cursor: str | None = Query(None, description="Cursor for keyset pagination"),
        limit: int = Query(50, ge=1, le=200, description="Items per page"),
    ):
        self.cursor = cursor
        self.limit = limit


Pagination = Annotated[PaginationParams, Depends()]


# ── Correlation ID ──
async def get_correlation_id(
    x_correlation_id: str = Header(default_factory=lambda: str(uuid.uuid4())),
) -> str:
    return x_correlation_id
