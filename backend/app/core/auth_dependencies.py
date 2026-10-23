"""FastAPI dependency for authenticated gUSo account endpoints."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.database.database import get_db
from app.database.models import User

# Swagger UI will show the Bearer authentication option for protected routes.
bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Resolve the signed access token to an existing database user."""
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Not authenticated or access token is invalid or expired.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise unauthorized

    try:
        user_id = decode_access_token(credentials.credentials)
    except ValueError as exc:
        raise unauthorized from exc

    user = db.get(User, user_id)
    if user is None:
        raise unauthorized

    return user