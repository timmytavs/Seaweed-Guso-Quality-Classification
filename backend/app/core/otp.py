
import secrets
from datetime import datetime, timedelta, timezone

from app.core.security import (
    hash_password,
    verify_password,
)


OTP_EXPIRATION_MINUTES = 5
OTP_MAX_ATTEMPTS = 5
OTP_RESEND_COOLDOWN_SECONDS = 60


def _valid_otp(otp: str) -> bool:
    return (
        isinstance(otp, str)
        and len(otp) == 6
        and otp.isascii()
        and otp.isdigit()
    )


# Generate a secure 6-digit code.
def generate_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


# Hash the OTP before database storage.
def hash_otp(otp: str) -> str:
    if not _valid_otp(otp):
        raise ValueError("OTP must contain exactly 6 digits.")

    return hash_password(otp)


# Compare a submitted code against the stored hash.
def verify_otp(otp: str, stored_hash: str) -> bool:
    if not _valid_otp(otp):
        return False

    return verify_password(otp, stored_hash)


# Generate expiration time (UTC, compatible with our database).
def otp_expiration() -> datetime:
    now = datetime.now(timezone.utc).replace(tzinfo=None)

    return now + timedelta(minutes=OTP_EXPIRATION_MINUTES)


# Check whether the code has expired.
def is_otp_expired(expires_at: datetime) -> bool:
    now = datetime.now(timezone.utc).replace(tzinfo=None)

    return now >= expires_at
