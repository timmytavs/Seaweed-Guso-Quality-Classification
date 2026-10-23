from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.database.models import (
    User,
    ClassificationRecord,
    ClassificationImage,
    OtpVerification
)


# =====================================================
# GET USER BY EMAIL
# =====================================================

def get_user_by_email(
    db: Session,
    email: str
):

    return (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )


# =====================================================
# GET USER BY CONTACT NUMBER
# =====================================================

def get_user_by_contact_num(
    db: Session,
    contact_num: str
):

    return (
        db.query(User)
        .filter(
            User.contact_num == contact_num
        )
        .first()
    )


# =====================================================
# GET USER BY ID
# =====================================================

def get_user_by_id(
    db: Session,
    user_id: int
):

    return (
        db.query(User)
        .filter(
            User.user_id == user_id
        )
        .first()
    )


# =====================================================
# CREATE USER
# =====================================================

def create_user(
    db: Session,
    full_name: str,
    email: str | None,
    contact_num: str,
    password_hash: str
):

    user = User(
        full_name=full_name,
        email=email,
        contact_num=contact_num,
        password_hash=password_hash,
        is_verified=False
    )

    db.add(user)

    db.commit()

    db.refresh(user)

    return user



# =====================================================
# SAVE CLASSIFICATION RESULT
# =====================================================

def create_classification_record(
    db: Session,
    user_id: int,
    quality_grade: str,
    confidence: float,
    model_name: str
):


    record = ClassificationRecord(

        user_id=user_id,

        # Temporary storage:
        # Until quality model exists,
        # we store detected species here.
        quality_grade=quality_grade,

        confidence_score=confidence,

        model_name=model_name
    )


    db.add(record)

    db.commit()

    db.refresh(record)


    return record



# =====================================================
# SAVE IMAGE
# =====================================================

def create_classification_image(
    db: Session,
    classification_id: int,
    image_bytes: bytes,
    file_name: str,
    mime_type: str
):


    image = ClassificationImage(

        classification_id=classification_id,

        image_data=image_bytes,

        file_name=file_name,

        mime_type=mime_type
    )


    db.add(image)

    db.commit()

    db.refresh(image)


    return image



# =====================================================
# GET USER HISTORY
# =====================================================

def get_user_history(
    db: Session,
    user_id: int
):

    records = (
        db.query(
            ClassificationRecord
        )
        .filter(
            ClassificationRecord.user_id == user_id
        )
        .order_by(
            ClassificationRecord.classified_at.desc()
        )
        .all()
    )


    return records



# =====================================================
# OTP DATABASE OPERATIONS
# =====================================================

def _utc_now():
    return datetime.now(timezone.utc).replace(tzinfo=None)


# =====================================================
# CREATE OTP RECORD
# =====================================================

def create_otp_record(
    db: Session,
    user_id: int,
    purpose: str,
    otp_hash: str,
    expires_at: datetime
):

    now = _utc_now()

    # Invalidate previous unused codes
    # for the same user and purpose.
    db.query(OtpVerification).filter(
        OtpVerification.user_id == user_id,
        OtpVerification.purpose == purpose,
        OtpVerification.verified_at.is_(None),
        OtpVerification.expires_at > now
    ).update(
        {OtpVerification.expires_at: now},
        synchronize_session=False
    )

    otp_record = OtpVerification(
        user_id=user_id,
        otp_hash=otp_hash,
        purpose=purpose,
        expires_at=expires_at,
        verified_at=None,
        attempts=0,
        created_at=now
    )

    try:
        db.add(otp_record)
        db.commit()
        db.refresh(otp_record)
    except Exception:
        db.rollback()
        raise

    return otp_record


# =====================================================
# GET LATEST PENDING OTP
# =====================================================

def get_pending_otp(
    db: Session,
    user_id: int,
    purpose: str
):

    return (
        db.query(OtpVerification)
        .filter(
            OtpVerification.user_id == user_id,
            OtpVerification.purpose == purpose,
            OtpVerification.verified_at.is_(None)
        )
        .order_by(
            OtpVerification.created_at.desc(),
            OtpVerification.otp_id.desc()
        )
        .first()
    )


# =====================================================
# INCREASE FAILED ATTEMPTS
# =====================================================

def increment_otp_attempts(
    db: Session,
    otp_record: OtpVerification
):

    db.query(OtpVerification).filter(
        OtpVerification.otp_id == otp_record.otp_id
    ).update(
        {
            OtpVerification.attempts:
                OtpVerification.attempts + 1
        },
        synchronize_session=False
    )

    db.commit()
    db.refresh(otp_record)

    return otp_record


# =====================================================
# MARK OTP AS VERIFIED
# =====================================================

def mark_otp_verified(
    db: Session,
    otp_record: OtpVerification
):

    otp_record.verified_at = _utc_now()

    db.commit()
    db.refresh(otp_record)

    return otp_record
