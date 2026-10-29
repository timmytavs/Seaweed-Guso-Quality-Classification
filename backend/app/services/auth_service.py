import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[2] / ".env")



from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
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

    # Email is OPTIONAL.
    email = (
        str(data.email).strip().lower()
        if data.email
        else None
    )

    # Normalize contact number before checking or saving it.
    contact_num = data.contact_num.strip()

    # Check for duplicates ONLY when email is provided.
    if email is not None:
        existing_email = get_user_by_email(db, email)

        if existing_email is not None:
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

# def login_user(
#     db: Session,
#     data: LoginRequest
# ):

#     identifier = data.identifier.strip()

#     password = data.password


#     # ---------------------------------------------
#     # FIND USER
#     # ---------------------------------------------

#     user = None


#     if "@" in identifier:

#         user = get_user_by_email(
#             db,
#             identifier.lower()
#         )

#     else:

#         user = get_user_by_contact_num(
#             db,
#             identifier
#         )


#     # ---------------------------------------------
#     # USER NOT FOUND
#     # ---------------------------------------------

#     if user is None:

#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Invalid email/contact number or password."
#         )


#     # ---------------------------------------------
#     # VERIFY PASSWORD
#     # ---------------------------------------------

#     password_valid = verify_password(
#         password,
#         user.password_hash
#     )


#     if not password_valid:

#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Invalid email/contact number or password."
#         )


#     # ---------------------------------------------
#     # SUCCESS RESPONSE
#     # ---------------------------------------------

#     return {
#         "message": "Login successful.",
#         "user": {
#             "user_id": user.user_id,
#             "full_name": user.full_name,
#             "email": user.email,
#             "contact_num": user.contact_num,
#             "is_verified": user.is_verified
#         }
#     }





# =====================================================
# LOGIN USER — MOBILE VERIFICATION REQUIRED
# =====================================================

def login_user(db: Session, data: LoginRequest):

    identifier = data.identifier.strip()

    # Find the account using email or contact number.
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

    # Check if the account exists.
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/contact number or password."
        )

    # Verify password before revealing verification status.
    if not verify_password(
        data.password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/contact number or password."
        )

    # Require successful SMS verification.
    # 
    
    # Presentation mode — temporarily skip SMS verification.
# Default is False so verification stays required normally.
    demo_mode = (
        os.getenv("GUSO_DEMO_MODE", "false").lower()
        == "true"
    )

    if not demo_mode:
        if not user.contact_verified or not user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    "Your mobile number is not verified. "
                    "Please complete SMS verification before logging in."
                )
            )

    # Email is optional and does not require verification.
    access_token = create_access_token(
        user_id=user.user_id,
        token_version=user.auth_token_version,
    )

    return {
        "message": "Login successful.",
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "user_id": user.user_id,
            "full_name": user.full_name,
            "email": user.email,
            "contact_num": user.contact_num,
            "is_verified": user.is_verified
        }
    }
