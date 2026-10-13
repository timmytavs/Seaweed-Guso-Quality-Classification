from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.security import (
    hash_password,
    verify_password
)

from app.database.repository import (
    get_user_by_email,
    get_user_by_contact_num,
    create_user,
)

from app.schemas.auth import (
    RegisterRequest,
    LoginRequest
)


# =====================================================
# REGISTER USER
# =====================================================

def register_user(
    db: Session,
    data: RegisterRequest
):
    

    # ---------------------------------------------
    # CLEAN INPUT
    # ---------------------------------------------

    first_name = data.first_name.strip()
    last_name = data.last_name.strip()

    full_name = f"{first_name} {last_name}"

    email = (
    str(data.email).lower().strip()
    if data.email
    else None
)

    contact_num = data.contact_num.strip()


    # ---------------------------------------------
    # CHECK DUPLICATE EMAIL
    # ---------------------------------------------

    existing_email = get_user_by_email(
        db,
        email
    )

    if existing_email:

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered."
        )


    # ---------------------------------------------
    # CHECK DUPLICATE CONTACT NUMBER
    # ---------------------------------------------

    existing_contact = get_user_by_contact_num(
        db,
        contact_num
    )

    if existing_contact:

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Contact number is already registered."
        )


    # ---------------------------------------------
    # HASH PASSWORD
    # ---------------------------------------------

    password_hash = hash_password(
        data.password
    )


    # ---------------------------------------------
    # CREATE USER
    # ---------------------------------------------

    try:

        user = create_user(
            db=db,
            full_name=full_name,
            email=email,
            contact_num=contact_num,
            password_hash=password_hash
        )

    except IntegrityError:

        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with the provided information already exists."
        )


    # ---------------------------------------------
    # RESPONSE
    # ---------------------------------------------

    return {
        "message": "Registration successful.",
        "user": {
            "user_id": user.user_id,
            "full_name": user.full_name,
            "email": user.email,
            "contact_num": user.contact_num,
            "is_verified": user.is_verified
        }
    }

# =====================================================
# LOGIN USER
# =====================================================

def login_user(
    db: Session,
    data: LoginRequest
):

    identifier = data.identifier.strip()

    password = data.password


    # ---------------------------------------------
    # FIND USER
    # ---------------------------------------------

    user = None


    if "@" in identifier:

        user = get_user_by_email(
            db,
            identifier.lower()
        )

    else:

        user = get_user_by_contact_num(
            db,
            identifier
        )


    # ---------------------------------------------
    # USER NOT FOUND
    # ---------------------------------------------

    if user is None:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/contact number or password."
        )


    # ---------------------------------------------
    # VERIFY PASSWORD
    # ---------------------------------------------

    password_valid = verify_password(
        password,
        user.password_hash
    )


    if not password_valid:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/contact number or password."
        )


    # ---------------------------------------------
    # SUCCESS RESPONSE
    # ---------------------------------------------

    return {
        "message": "Login successful.",
        "user": {
            "user_id": user.user_id,
            "full_name": user.full_name,
            "email": user.email,
            "contact_num": user.contact_num,
            "is_verified": user.is_verified
        }
    }