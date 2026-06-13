"""Notification service: send push notifications."""

from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def get_user_push_tokens(db: AsyncSession, user_id: UUID) -> list[dict]:
    """Get all active push tokens for a user."""
    result = await db.execute(
        text("""
            SELECT push_token, push_provider
            FROM devices
            WHERE user_id = :uid
              AND is_active = TRUE
              AND push_token IS NOT NULL
              AND push_provider != 'none'
        """),
        {"uid": str(user_id)},
    )
    return [{"token": r.push_token, "provider": r.push_provider} for r in result.fetchall()]


async def log_notification(
    db: AsyncSession,
    user_id: UUID,
    notification_type: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    await db.execute(
        text("""
            INSERT INTO notification_log (id, user_id, notification_type, title, body, data)
            VALUES (:id, :uid, :type, :title, :body, :data)
        """),
        {
            "id": str(UUID(bytes=__import__('os').urandom(16))),
            "uid": str(user_id),
            "type": notification_type,
            "title": title,
            "body": body,
            "data": __import__('json').dumps(data or {}),
        },
    )


async def get_notification_history(
    db: AsyncSession, user_id: UUID, limit: int = 50
) -> list[dict]:
    result = await db.execute(
        text("""
            SELECT id, notification_type, title, body, data, sent_at, delivered, opened
            FROM notification_log
            WHERE user_id = :uid
            ORDER BY sent_at DESC
            LIMIT :limit
        """),
        {"uid": str(user_id), "limit": limit},
    )
    return [
        {
            "id": str(r.id),
            "notification_type": r.notification_type,
            "title": r.title,
            "body": r.body,
            "sent_at": r.sent_at.isoformat() if r.sent_at else None,
            "delivered": r.delivered,
            "opened": r.opened,
        }
        for r in result.fetchall()
    ]


async def send_push_notification(
    tokens: list[dict],
    title: str,
    body: str,
    data: dict | None = None,
) -> dict:
    """Send push notification via Firebase Admin SDK.

    In production, this would use firebase_admin.messaging.
    Returns a summary of sent/failed.
    """
    sent = 0
    failed = 0

    # TODO: Integrate Firebase Admin SDK
    # from firebase_admin import messaging
    # for token_info in tokens:
    #     try:
    #         message = messaging.Message(
    #             notification=messaging.Notification(title=title, body=body),
    #             data=data or {},
    #             token=token_info["token"],
    #         )
    #         messaging.send(message)
    #         sent += 1
    #     except Exception:
    #         failed += 1

    return {"sent": sent, "failed": failed, "total": len(tokens)}
