"""Common Pydantic schemas: pagination, errors, success responses."""

from datetime import datetime
from typing import Any, Generic, TypeVar
from uuid import UUID

from pydantic import BaseModel, Field

T = TypeVar("T")


# ── Error responses ──
class ErrorResponse(BaseModel):
    error: str
    message: str
    details: dict[str, Any] | None = None


class ValidationErrorDetail(BaseModel):
    field: str
    message: str
    type: str


class ValidationErrorResponse(BaseModel):
    error: str = "validation_error"
    message: str = "Request validation failed"
    details: list[ValidationErrorDetail]


# ── Success response ──
class SuccessResponse(BaseModel, Generic[T]):
    success: bool = True
    data: T


class MessageResponse(BaseModel):
    success: bool = True
    message: str


# ── Pagination ──
class CursorPage(BaseModel, Generic[T]):
    items: list[T]
    next_cursor: str | None = None
    has_more: bool = False
    total_count: int | None = None


# ── Health ──
class HealthResponse(BaseModel):
    status: str
    version: str
    uptime_seconds: float
