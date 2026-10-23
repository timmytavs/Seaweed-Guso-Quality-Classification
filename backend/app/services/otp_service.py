
from datetime import datetime, timezone
from typing import Callable

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.otp import (
    generate_otp,
    hash_otp,
    verify_otp,
    otp_expiration,
    is_otp_expired,
    OTP_MAX_ATTEMPTS,
    OTP_RESEND_COOLDOWN_SECONDS,
    OTP_EXPIRATION_MINUTES,
)

from app.database.repository import (
    get_user_by_id,
    create_otp_record,
    get_pending_otp,
    increment_otp_attempts,
)


CONTACT_VERIFICATION = "contact_verification"
# EMAIL_VERIFICATION = "email_verification"


def utc_now():
    return datetime.now(timezone.utc).replace(
        tzinfo=None
    )


# def validate_purpose(purpose: str):
#     if purpose not in (
#         CONTACT_VERIFICATION,
#         EMAIL_VERIFICATION,
#     ):
#         raise ValueError("Invalid OTP purpose.")


def validate_purpose(purpose: str):
    if purpose != CONTACT_VERIFICATION:
        raise HTTPException(
            status_code=400,
            detail="Only mobile number verification is supported."
        )


# def get_verification_destination(user, purpose):
#     if purpose == CONTACT_VERIFICATION:
#         return user.contact_num

#     if purpose == EMAIL_VERIFICATION:
#         if not user.email:
#             raise HTTPException(
#                 status_code=400,
#                 detail="This account has no email address."
#             )

#         return user.email

#     raise ValueError("Invalid OTP purpose.")


def get_verification_destination(user, purpose):
    validate_purpose(purpose)
    return user.contact_num


# =====================================================
# GENERATE, STORE AND DISPATCH OTP
# =====================================================

def send_verification_otp(
    db: Session,
    user_id: int,
    purpose: str,
    deliver_code: Callable[[str, str], None],
):
    """
    deliver_code(destination, code) must be a trusted
    backend SMS/email sender.

    Never return the plaintext OTP to Flutter.
    """

    validate_purpose(purpose)

    user = get_user_by_id(db, user_id)

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found."
        )

    destination = get_verification_destination(
        user, purpose
    )

    # if purpose == CONTACT_VERIFICATION:
    #     already_verified = user.contact_verified
    # else:
    #     already_verified = user.email_verified
    
    already_verified = user.contact_verified

    if already_verified:
        raise HTTPException(
            status_code=400,
            detail="This contact method is already verified."
        )

    previous_otp = get_pending_otp(
        db, user_id, purpose
    )

    if (
        previous_otp is not None
        and previous_otp.created_at is not None
    ):
        elapsed = (
            utc_now() - previous_otp.created_at
        ).total_seconds()

        if (
            elapsed < OTP_RESEND_COOLDOWN_SECONDS
            and not is_otp_expired(
                previous_otp.expires_at
            )
        ):
            raise HTTPException(
                status_code=429,
                detail="Please wait before requesting another OTP."
            )

    code = generate_otp()

    record = create_otp_record(
        db=db,
        user_id=user_id,
        purpose=purpose,
        otp_hash=hash_otp(code),
        expires_at=otp_expiration(),
    )

    try:
        deliver_code(destination, code)
    except Exception:
        # Invalidate an OTP that could not be delivered.
        record.expires_at = utc_now()
        db.commit()

        raise HTTPException(
            status_code=503,
            detail="Unable to send verification code. Please try again."
        )

    return {
        "message": "Verification code sent.",
        "expires_in_minutes": OTP_EXPIRATION_MINUTES,
    }


# =====================================================
# VERIFY OTP
# =====================================================

def verify_verification_otp(
    db: Session,
    user_id: int,
    purpose: str,
    code: str,
):
    validate_purpose(purpose)

    user = get_user_by_id(db, user_id)

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found."
        )

    get_verification_destination(user, purpose)

    record = get_pending_otp(
        db, user_id, purpose
    )

    if record is None:
        raise HTTPException(
            status_code=400,
            detail="No pending verification code."
        )

    if is_otp_expired(record.expires_at):
        raise HTTPException(
            status_code=400,
            detail="Verification code has expired."
        )

    if record.attempts >= OTP_MAX_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail="Too many incorrect attempts. Request a new code."
        )

    if not verify_otp(code, record.otp_hash):
        increment_otp_attempts(db, record)

        raise HTTPException(
            status_code=400,
            detail="Incorrect verification code."
        )

    # Mark the code as used.
    record.verified_at = utc_now()

    # Update the relevant verification flag.
    # if purpose == CONTACT_VERIFICATION:
    #     user.contact_verified = True
    # else:
    #     user.email_verified = True

    # # Contact is mandatory.
    # # Email verification is required only if email exists.
    # user.is_verified = (
    #     bool(user.contact_verified)
    #     and (
    #         user.email is None
    #         or bool(user.email_verified)
    #     )
    # )
    
    # Mobile OTP verification is required.
    user.contact_verified = True

    # Email is optional and does not require OTP.
    user.is_verified = bool(user.contact_verified)

    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        raise

    return {
        "message": "Verification successful.",
        "contact_verified": user.contact_verified,
        "email_verified": user.email_verified,
        "is_verified": user.is_verified,
    }
