"""Password security and signed JWT access tokens for the gUSo API."""

import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from dotenv import load_dotenv
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash


# Load backend/.env when the module is used directly during development.
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


def create_access_token(user_id: int) -> str:
    """Return a one-hour JWT for an authenticated account."""
    if not isinstance(user_id, int) or isinstance(user_id, bool) or user_id <= 0:
        raise ValueError("user_id must be a positive integer.")

    now = datetime.now(timezone.utc)
    claims = {
        "sub": str(user_id),
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "iat": now,
        "exp": now + timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES),
    }

    return jwt.encode(claims, _get_jwt_secret(), algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> int:
    """Validate an access token and return its user_id or raise ValueError."""
    try:
        claims = jwt.decode(
            token,
            _get_jwt_secret(),
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
            options={"require": ["sub", "iss", "aud", "iat", "exp"]},
        )
        user_id = int(claims["sub"])

        if user_id <= 0:
            raise ValueError("Invalid user ID.")

        return user_id
    except (InvalidTokenError, ValueError, TypeError, KeyError) as exc:
        raise ValueError("Invalid or expired access token.") from exc
