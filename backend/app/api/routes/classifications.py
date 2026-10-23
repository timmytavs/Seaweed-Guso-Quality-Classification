
"""Authenticated gUSo classification and explicit-save endpoints."""

from io import BytesIO

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from PIL import Image
from sqlalchemy.orm import Session

from app.core.auth_dependencies import get_current_user
from app.database.database import get_db
from app.database.models import ClassificationRecord, User
from app.schemas.classification import ClassificationResponse
from app.services.classification_service import classify_image


router = APIRouter(
    prefix="/classifications",
    tags=["Classification"],
)


# =====================================================
# CLASSIFICATION ENDPOINT
# =====================================================

@router.post("/", response_model=ClassificationResponse)
async def classify_uploaded_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Classify an image and associate its record with its owner."""

    # Check allowed image types.
    allowed_types = [
        "image/jpeg",
        "image/png",
    ]

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Only JPG and PNG images are allowed.",
        )

    # Read image bytes.
    image_bytes = await file.read()

    # Open and validate the uploaded image.
    try:
        image = Image.open(
            BytesIO(image_bytes)
        ).convert("RGB")

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail="Invalid image.",
        ) from exc

    # Classify image and associate it with the
    # currently authenticated user.
    #
    # The record is initially stored as is_saved=False.
    result = classify_image(
        db=db,
        image=image,
        image_bytes=image_bytes,
        file_name=file.filename or "upload",
        mime_type=file.content_type,
        user_id=current_user.user_id,
    )

    return {
        "filename": file.filename or "upload",
        "result": result,
    }


# =====================================================
# SAVE CLASSIFICATION ENDPOINT
# =====================================================

@router.post("/{classification_id}/save")
def save_classification(
    classification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Save a classification only when it belongs
    to the currently authenticated user.
    """

    # Find classification belonging to this user.
    record = (
        db.query(ClassificationRecord)
        .filter(
            ClassificationRecord.classification_id
            == classification_id,

            ClassificationRecord.user_id
            == current_user.user_id,
        )
        .first()
    )

    # Record not found or belongs to another user.
    if record is None:
        raise HTTPException(
            status_code=404,
            detail="Classification not found.",
        )

    # Mark as saved without creating duplicates.
    if not record.is_saved:
        record.is_saved = True
        db.commit()

    return {
        "message": "Classification saved successfully.",
        "classification_id": record.classification_id,
        "is_saved": True,
    }
