
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    LargeBinary,
    Numeric
)

from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB

from datetime import datetime

from app.database.database import Base


# =====================================================
# USERS TABLE
# =====================================================

class User(Base):

    __tablename__ = "users"

    user_id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    email = Column(
        String(255),
        nullable=True,
        unique=True,
        index=True
    )

    full_name = Column(
        String(200),
        nullable=False
    )

    contact_num = Column(
        String(120),
        nullable=False,
        unique=True
    )

    password_hash = Column(
        String,
        nullable=False
    )

    # Increment after a completed password reset to revoke existing JWTs.
    # Token creation and validation must also enforce this version.
    auth_token_version = Column(
        Integer,
        nullable=False,
        default=0,
        server_default="0"
    )

    is_verified = Column(
        Boolean,
        default=False
    )

    contact_verified = Column(
        Boolean,
        nullable=False,
        default=False
    )

    email_verified = Column(
        Boolean,
        nullable=False,
        default=False
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow
    )

    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    classifications = relationship(
        "ClassificationRecord",
        back_populates="user"
    )


# =====================================================
# CLASSIFICATION RECORDS TABLE
# =====================================================

class ClassificationRecord(Base):

    __tablename__ = "classification_records"

    classification_id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id = Column(
        Integer,
        ForeignKey("users.user_id"),
        nullable=True
    )

    quality_grade = Column(
        String(250),
        nullable=True
    )

    confidence_score = Column(
        Numeric(5,4),
        nullable=False
    )

    model_name = Column(
        String(150),
        nullable=False
    )

    is_saved = Column(
        Boolean,
        nullable=False,
        default=False,
        server_default="false"
    )

    # Stores the complete classification response.
    # Existing classifications will initially contain NULL.
    analysis_result = Column(
        JSONB,
        nullable=True
    )

    classified_at = Column(
        DateTime,
        default=datetime.utcnow
    )

    user = relationship(
        "User",
        back_populates="classifications"
    )

    image = relationship(
        "ClassificationImage",
        back_populates="classification",
        uselist=False
    )


# =====================================================
# CLASSIFICATION IMAGES TABLE
# =====================================================

class ClassificationImage(Base):

    __tablename__ = "classification_images"

    image_id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    classification_id = Column(
        Integer,
        ForeignKey(
            "classification_records.classification_id"
        ),
        nullable=False
    )

    image_data = Column(
        LargeBinary,
        nullable=False
    )

    file_name = Column(
        String(300),
        nullable=False
    )

    mime_type = Column(
        String(50),
        nullable=False
    )

    uploaded_at = Column(
        DateTime,
        default=datetime.utcnow
    )

    classification = relationship(
        "ClassificationRecord",
        back_populates="image"
    )


# =====================================================
# OTP VERIFICATIONS TABLE
# =====================================================

class OtpVerification(Base):

    __tablename__ = "otp_verifications"

    otp_id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id = Column(
        Integer,
        ForeignKey(
            "users.user_id"
        ),
        nullable=False
    )

    otp_hash = Column(
        String,
        nullable=False
    )

    purpose = Column(
        String(250),
        nullable=False
    )

    expires_at = Column(
        DateTime,
        nullable=False
    )

    verified_at = Column(
        DateTime,
        nullable=True
    )

    attempts = Column(
        Integer,
        nullable=False,
        default=0
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow
    )
