
"""Password security, signed JWTs, and recovery-code helpers for gUSo."""

import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from dotenv import load_dotenv
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash


# Load backend/.env when this module is used directly during development.
# Environment variables supplied by the host take precedence.
load_dotenv(Path(__file__).resolve().parents[2] / ".env")

password_hasher = PasswordHash.recommended()

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "guso-api"
JWT_AUDIENCE = "guso-app"
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 60


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_hasher.verify(plain_password, hashed_password)


def _get_jwt_secret() -> str:
    secret = os.getenv("JWT_SECRET_KEY", "")

    if len(secret.encode("utf-8")) < 32:
        raise RuntimeError(
            "JWT_SECRET_KEY must be configured with at least 32 bytes "
            "of unpredictable secret material."
        )

    return secret


def _validate_user_id(user_id: int) -> None:
    if type(user_id) is not int or user_id <= 0:
        raise ValueError("user_id must be a positive integer.")


def _validate_token_version(token_version: int) -> None:
    if type(token_version) is not int or token_version < 0:
        raise ValueError("token_version must be a non-negative integer.")


def create_access_token(user_id: int, token_version: int = 0) -> str:
    """Issue a one-hour JWT with the account's authentication version.

    Defaulting the version to 0 keeps existing login calls working during
    migration. The login service must eventually pass the real DB version.
    """
    _validate_user_id(user_id)
    _validate_token_version(token_version)

    now = datetime.now(timezone.utc)
    claims = {
        "sub": str(user_id),
        "ver": token_version,
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "iat": now,
        "exp": now + timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES),
    }

    return jwt.encode(claims, _get_jwt_secret(), algorithm=JWT_ALGORITHM)


def decode_access_token_details(token: str) -> tuple[int, int]:
    """Verify a JWT and return (user_id, token_version).

    Legacy JWTs without a 'ver' claim are treated as version 0 until they
    expire. The authentication dependency must compare the returned version
    against User.auth_token_version to enforce revocation.
    """
    try:
        claims = jwt.decode(
            token,
            _get_jwt_secret(),
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
            options={"require": ["sub", "iss", "aud", "iat", "exp"]},
        )

        raw_user_id = claims["sub"]
        if not isinstance(raw_user_id, str) or not raw_user_id.isdecimal():
            raise ValueError("Invalid user ID.")
        user_id = int(raw_user_id)
        _validate_user_id(user_id)

        token_version = claims.get("ver", 0)
        _validate_token_version(token_version)

        return user_id, token_version
    except (InvalidTokenError, ValueError, TypeError, KeyError) as exc:
        raise ValueError("Invalid or expired access token.") from exc


def decode_access_token(token: str) -> int:
    """Preserve the existing API: validate a JWT and return its user ID."""
    user_id, _ = decode_access_token_details(token)
    return user_id


def generate_password_reset_otp() -> str:
    """Generate a cryptographically random six-digit recovery code."""
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_password_reset_otp(user_id: int, otp: str) -> str:
    """Produce a purpose- and user-bound HMAC digest for storing an OTP.

    Never store or log the raw code. The OTP service must separately enforce
    expiry, attempt limits, delivery through a verified channel and one-time use.
    """
    _validate_user_id(user_id)
    if not isinstance(otp, str) or len(otp) != 6 or not otp.isascii() or not otp.isdigit():
        raise ValueError("Password reset code must contain exactly six digits.")

    message = f"guso:password-reset:{user_id}:{otp}".encode("utf-8")
    return hmac.new(
        _get_jwt_secret().encode("utf-8"), message, hashlib.sha256
    ).hexdigest()


def verify_password_reset_otp(user_id: int, otp: str, stored_hash: str) -> bool:
    """Compare a supplied recovery code with its stored HMAC digest."""
    if not isinstance(stored_hash, str) or len(stored_hash) != 64:
        return False
    try:
        candidate_hash = hash_password_reset_otp(user_id, otp)
    except ValueError:
        return False
    return hmac.compare_digest(candidate_hash, stored_hash)
