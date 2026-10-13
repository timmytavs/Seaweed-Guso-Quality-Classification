from fastapi import (
    APIRouter,
    Depends,
    status
)

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