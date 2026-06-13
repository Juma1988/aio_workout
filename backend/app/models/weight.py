"""Weight entry model."""

import uuid

from sqlalchemy import (
    Column,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class WeightEntry(Base):
    __tablename__ = "weight_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    entry_date = Column(Date, nullable=False)
    weight_kg = Column(Numeric(5, 1), nullable=False)
    notes = Column(Text, nullable=True)
    source = Column(String(20), nullable=False, default="manual")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_weight_user_date", "user_id", "entry_date", unique=True, postgresql_where="deleted_at IS NULL"),
    )
