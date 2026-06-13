"""Device endpoints: register, list, deactivate."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.common import MessageResponse, SuccessResponse
from app.schemas.notifications import DeviceRegister, DeviceResponse
from app.services import device_service

router = APIRouter()


@router.post(
    "/register",
    response_model=SuccessResponse[DeviceResponse],
    summary="Register a device",
)
async def register_device(
    body: DeviceRegister,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    device = await device_service.register_device(db, user.id, body)
    return SuccessResponse(data=device)


@router.get(
    "/",
    response_model=SuccessResponse[list[DeviceResponse]],
    summary="List all user devices",
)
async def list_devices(
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    devices = await device_service.list_devices(db, user.id)
    return SuccessResponse(data=devices)


@router.delete(
    "/{device_id}",
    response_model=MessageResponse,
    summary="Deactivate a device",
)
async def deactivate_device(
    device_id: UUID,
    user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    await device_service.deactivate_device(db, device_id, user.id)
    return MessageResponse(message="Device deactivated")
