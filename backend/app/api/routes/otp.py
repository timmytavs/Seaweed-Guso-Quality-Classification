
# =====================================================
# FILE 30 — SMS OTP API ROUTES
# =====================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.database import get_db

from app.database.repository import (
    get_user_by_contact_num,
)

from app.core.security import verify_password

from app.schemas.otp import (
    SmsOtpRequest,
    SmsOtpVerifyRequest,
    SmsOtpSendResponse,
    SmsOtpVerifyResponse,
)

from app.services.otp_service import (
    send_verification_otp,
    verify_verification_otp,
    CONTACT_VERIFICATION,
)

from app.services.sms_service import (
    send_verification_sms,
    normalize_mobile_number,
)


# =====================================================
# ROUTER CONFIGURATION
# =====================================================

router = APIRouter(
    prefix="/auth/otp",
    tags=["SMS Verification"],
)


# =====================================================
# VALIDATE USER CREDENTIALS
# =====================================================

def authenticate_verification_user(
    db: Session,
    contact_num: str,
    password: str,
):

    # Normalize the number to Philippine format.
    normalized = normalize_mobile_number(
        contact_num
    )

    national = normalized[2:]

    # Support common stored number formats.
    candidates = [
        contact_num.strip(),
        "0" + national,
        normalized,
        "+" + normalized,
        national,
    ]

    user = None

    for number in dict.fromkeys(candidates):
        user = get_user_by_contact_num(
            db,
            number
        )

        if user is not None:
            break

    # Do not disclose whether an account exists.
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid mobile number or password.",
        )

    # Validate the registered account password.
    if not verify_password(
        password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid mobile number or password.",
        )

    return user


# =====================================================
# POST /auth/otp/send
# =====================================================

@router.post(
    "/send",
    response_model=SmsOtpSendResponse,
    status_code=status.HTTP_200_OK,
)
def send_sms_otp(
    data: SmsOtpRequest,
    db: Session = Depends(get_db),
):

    # Verify account ownership first.
    user = authenticate_verification_user(
        db=db,
        contact_num=data.contact_num,
        password=data.password,
    )

    # Generate OTP, save its hash and
    # send the code through Semaphore.
    result = send_verification_otp(
        db=db,
        user_id=user.user_id,
        purpose=CONTACT_VERIFICATION,
        deliver_code=send_verification_sms,
    )

    # Never return the OTP itself.
    return result


# =====================================================
# POST /auth/otp/verify
# =====================================================

@router.post(
    "/verify",
    response_model=SmsOtpVerifyResponse,
    status_code=status.HTTP_200_OK,
)
def verify_sms_otp(
    data: SmsOtpVerifyRequest,
    db: Session = Depends(get_db),
):

    # Verify account ownership first.
    user = authenticate_verification_user(
        db=db,
        contact_num=data.contact_num,
        password=data.password,
    )

    # Validate submitted OTP against
    # the hashed code in PostgreSQL.
    result = verify_verification_otp(
        db=db,
        user_id=user.user_id,
        purpose=CONTACT_VERIFICATION,
        code=data.code,
    )

    return result
