"""Auth endpoints: register, login, refresh, logout."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    RefreshRequest,
    TokenPair,
)
from app.schemas.common import MessageResponse
from app.services import auth_service

router = APIRouter()


@router.post(
    "/register",
    response_model=TokenPair,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    try:
        user = await auth_service.register_user(
            db, body.email, body.password, body.display_name
        )
        return await auth_service.generate_token_pair(db, user)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.post(
    "/login",
    response_model=TokenPair,
    summary="Login with email and password",
)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await auth_service.authenticate_user(db, body.email, body.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return await auth_service.generate_token_pair(db, user)


@router.post(
    "/refresh",
    response_model=TokenPair,
    summary="Refresh access token",
)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    from app.dependencies import decode_token

    payload = auth_service.decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    from sqlalchemy import text
    import hashlib

    token_hash = hashlib.sha256(body.refresh_token.encode()).hexdigest()
    result = await db.execute(
        text("""
            SELECT rt.user_id, u.email
            FROM refresh_tokens rt
            JOIN users u ON u.id = rt.user_id
            WHERE rt.token_hash = :hash
              AND rt.revoked_at IS NULL
              AND rt.expires_at > NOW()
        """),
        {"hash": token_hash},
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=401, detail="Refresh token expired or revoked")

    # Revoke old refresh token
    await db.execute(
        text("UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = :hash"),
        {"hash": token_hash},
    )

    from app.models.user import User

    user_result = await db.execute(
        text("SELECT * FROM users WHERE id = :uid"),
        {"uid": str(row.user_id)},
    )
    user = User(**dict(user_result.first()._mapping))

    return await auth_service.generate_token_pair(db, user)


@router.post(
    "/logout",
    response_model=MessageResponse,
    summary="Logout (revoke current refresh token)",
)
async def logout(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    import hashlib
    from sqlalchemy import text

    token_hash = hashlib.sha256(body.refresh_token.encode()).hexdigest()
    await db.execute(
        text("UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = :hash"),
        {"hash": token_hash},
    )
    return MessageResponse(message="Logged out successfully")


@router.get(
    "/me",
    response_model=dict,
    summary="Get current user profile",
)
async def get_me(user: CurrentUser):
    return {
        "id": str(user.id),
        "email": user.email,
        "display_name": user.display_name,
        "avatar_url": user.avatar_url,
        "is_premium": user.is_premium,
    }
