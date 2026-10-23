"""Authenticated endpoints for saved gUSo classification history."""

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.auth_dependencies import get_current_user
from app.database.database import get_db
from app.database.models import User
from app.services.history_service import fetch_history, fetch_saved_image


router = APIRouter(
    prefix="/history",
    tags=["History"],
)


@router.get("/me")
def get_my_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    records = fetch_history(
        db,
        current_user.user_id,
    )

    return {
        "user_id": current_user.user_id,
        "records": records,
    }


@router.get(
    "/{classification_id}/image",
    response_class=Response,
    responses={
        200: {
            "description": "Original image for the authenticated user's saved classification",
            "content": {"image/jpeg": {}, "image/png": {}},
        },
        404: {"description": "No accessible saved image was found"},
    },
)
def get_saved_classification_image(
    classification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Never take the user ID from the URL or request body.
    image = fetch_saved_image(
        db=db,
        user_id=current_user.user_id,
        classification_id=classification_id,
    )

    # The same response is used for nonexistent, unsaved, and other users' records.
    if image is None:
        raise HTTPException(
            status_code=404,
            detail="Saved classification image not found.",
        )

    mime_type = image["mime_type"]
    if mime_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(
            status_code=415,
            detail="Stored image type is not supported.",
        )

    # Send the original bytes rather than encoding them into JSON/base64.
    return Response(
        content=image["image_bytes"],
        media_type=mime_type,
        headers={
            "Cache-Control": "private, no-store",
            "X-Content-Type-Options": "nosniff",
        },
    )
