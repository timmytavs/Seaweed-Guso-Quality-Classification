
"""FastAPI dependency for authenticated gUSo account endpoints.

A signed JWT must belong to an existing user AND carry the current
account token version. Resetting a password will increment that version,
invalidating previously issued tokens on protected endpoints.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token_details
from app.database.database import get_db
from app.database.models import User

# Swagger UI will show the Bearer authentication option for protected routes.
bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Resolve a valid Bearer JWT to an existing, non-revoked account."""
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Not authenticated or access token is invalid or expired.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise unauthorized

    try:
        user_id, token_version = decode_access_token_details(
            credentials.credentials
        )
    except ValueError as exc:
        raise unauthorized from exc

    user = db.get(User, user_id)
    if user is None:
        raise unauthorized

    # A successful password reset increments the database version.
    # A JWT issued before that reset must no longer authenticate.
    if user.auth_token_version != token_version:
        raise unauthorized

    return user
