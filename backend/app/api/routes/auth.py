
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status
)

from importlib import import_module

from sqlalchemy.orm import Session

from app.database.database import get_db

from app.schemas.auth import (
    RegisterRequest,
    RegisterResponse,
    LoginRequest,
    LoginResponse
)

from app.services.auth_service import (
    register_user,
    login_user
)

from app.schemas.password_reset import (
    PasswordResetRequest,
    PasswordResetConfirm,
    PasswordResetResponse,
)


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


# =====================================================
# REGISTER
# =====================================================

@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db)
):

    return register_user(
        db=db,
        data=data
    )

# =====================================================
# LOGIN
# =====================================================

@router.post(
    "/login",
    response_model=LoginResponse,
    status_code=status.HTTP_200_OK
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db)
):

    return login_user(
        db=db,
        data=data
    )


# =====================================================
# PASSWORD RECOVERY (SERVICE INTEGRATION PENDING)
# =====================================================


def _password_reset_service():
    """Load the recovery service when called, not at application startup.

    This lets existing Login and Register routes continue working while the
    separate secure OTP service is being built in the next file. Requests
    fail closed with HTTP 503 until that service is available.
    """
    try:
        return import_module("app.services.password_reset_service")
    except ModuleNotFoundError as exc:
        if exc.name != "app.services.password_reset_service":
            raise
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Password recovery is not configured yet.",
        ) from exc


@router.post(
    "/password-reset/request",
    response_model=PasswordResetResponse,
    status_code=status.HTTP_202_ACCEPTED,
    responses={503: {"description": "Recovery service is not yet configured"}},
)
def request_password_reset(
    data: PasswordResetRequest,
    db: Session = Depends(get_db),
):
    """Request an OTP without exposing whether the account exists.

    Expected service contract:
        request_password_reset(db=Session, identifier=str) -> None

    The service must use an eligible verified recovery channel, enforce
    rate limits, and never return the OTP to the API caller.
    """
    service = _password_reset_service()
    service.request_password_reset(db=db, identifier=data.identifier)
    return PasswordResetResponse(
        message=(
            "If an account with a verified recovery method exists, "
            "a recovery code will be sent."
        )
    )


@router.post(
    "/password-reset/confirm",
    response_model=PasswordResetResponse,
    status_code=status.HTTP_200_OK,
    responses={503: {"description": "Recovery service is not yet configured"}},
)
def confirm_password_reset(
    data: PasswordResetConfirm,
    db: Session = Depends(get_db),
):
    """Confirm a one-time code and change the password.

    Expected service contract:
        confirm_password_reset(
            db=Session, identifier=str, code=str, new_password=str
        ) -> None

    The service must enforce code expiry, attempt limits, single use,
    and secure password hashing before committing to PostgreSQL.
    """
    service = _password_reset_service()
    service.confirm_password_reset(
        db=db,
        identifier=data.identifier,
        code=data.code,
        new_password=data.new_password.get_secret_value(),
    )
    return PasswordResetResponse(
        message="Password updated successfully. Please log in again."
    )
