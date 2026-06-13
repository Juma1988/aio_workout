"""Device model for multi-device support."""

import uuid

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Index,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy import ForeignKey

from app.database import Base


class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_type = Column(String(20), nullable=False)  # ios, android, watchos, wearos, web
    device_name = Column(String(255), nullable=False, default="")
    os_version = Column(String(50), nullable=True)
    app_version = Column(String(20), nullable=True)
    push_token = Column(Text, nullable=True)
    push_provider = Column(String(20), nullable=True)  # fcm, apns, none
    is_active = Column(Boolean, nullable=False, default=True)
    last_sync_at = Column(DateTime(timezone=True), nullable=True)
    metadata_ = Column("metadata", JSONB, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_devices_user_active", "user_id", postgresql_where="deleted_at IS NULL AND is_active = TRUE"),
    )
