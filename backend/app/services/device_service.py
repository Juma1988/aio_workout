"""Device service: registration, sync tracking."""

from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.notifications import DeviceRegister, DeviceResponse


async def register_device(
    db: AsyncSession, user_id: UUID, data: DeviceRegister
) -> DeviceResponse:
    device_id = UUID(bytes=__import__('os').urandom(16))
    await db.execute(
        text("""
            INSERT INTO devices (id, user_id, device_type, device_name, os_version,
                                 app_version, push_token, push_provider)
            VALUES (:id, :uid, :type, :name, :os, :app, :push, :provider)
        """),
        {
            "id": str(device_id),
            "uid": str(user_id),
            "type": data.device_type,
            "name": data.device_name,
            "os": data.os_version,
            "app": data.app_version,
            "push": data.push_token,
            "provider": data.push_provider,
        },
    )

    return DeviceResponse(
        id=device_id,
        device_type=data.device_type,
        device_name=data.device_name,
        os_version=data.os_version,
        app_version=data.app_version,
        is_active=True,
        last_sync_at=None,
        created_at=None,
    )


async def list_devices(db: AsyncSession, user_id: UUID) -> list[DeviceResponse]:
    result = await db.execute(
        text("""
            SELECT id, device_type, device_name, os_version, app_version,
                   is_active, last_sync_at, created_at
            FROM devices
            WHERE user_id = :uid AND deleted_at IS NULL
            ORDER BY last_sync_at DESC NULLS LAST
        """),
        {"uid": str(user_id)},
    )
    return [
        DeviceResponse(
            id=r.id,
            device_type=r.device_type,
            device_name=r.device_name,
            os_version=r.os_version,
            app_version=r.app_version,
            is_active=r.is_active,
            last_sync_at=r.last_sync_at,
            created_at=r.created_at,
        )
        for r in result.fetchall()
    ]


async def update_sync_timestamp(db: AsyncSession, device_id: UUID) -> None:
    await db.execute(
        text("UPDATE devices SET last_sync_at = NOW() WHERE id = :did"),
        {"did": str(device_id)},
    )


async def deactivate_device(db: AsyncSession, device_id: UUID, user_id: UUID) -> None:
    await db.execute(
        text("""
            UPDATE devices SET is_active = FALSE, deleted_at = NOW()
            WHERE id = :did AND user_id = :uid
        """),
        {"did": str(device_id), "uid": str(user_id)},
    )
