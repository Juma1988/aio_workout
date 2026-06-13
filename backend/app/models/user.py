"""User SQLAlchemy model."""

import uuid

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Index,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(320), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    display_name = Column(String(100), nullable=False, default="")
    avatar_url = Column(Text, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(String(20), nullable=True)
    height_cm = Column(Numeric(5, 1), nullable=True)
    weight_kg = Column(Numeric(5, 1), nullable=True)
    is_premium = Column(Boolean, nullable=False, default=False)
    timezone = Column(String(50), nullable=False, default="UTC")
    locale = Column(String(10), nullable=False, default="en")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_users_active", "email", postgresql_where="deleted_at IS NULL"),
    )
