
"""Saved classification history and owner-checked image retrieval for gUSo."""

from sqlalchemy.orm import Session

from app.database.models import ClassificationImage, ClassificationRecord
from app.database.repository import get_user_history


def fetch_history(db: Session, user_id: int):
    """Return saved records for one user, without loading image binary data."""
    history = get_user_history(db, user_id)
    saved_records = [item for item in history if item.is_saved]

    if not saved_records:
        return []

    # One metadata query, rather than loading images one record at a time.
    saved_ids = [item.classification_id for item in saved_records]
    image_rows = (
        db.query(ClassificationImage.classification_id, ClassificationImage.file_name)
        .filter(ClassificationImage.classification_id.in_(saved_ids))
        .all()
    )
    image_names = {row.classification_id: row.file_name for row in image_rows}

    formatted_history = []
    for item in saved_records:
        file_name = image_names.get(item.classification_id)

        formatted_history.append(
            {
                "id": item.classification_id,
                "quality_grade": item.quality_grade,
                "confidence": round(float(item.confidence_score) * 100, 2),
                "model": item.model_name,
                "date": (
                    item.classified_at.strftime("%Y-%m-%d")
                    if item.classified_at
                    else None
                ),
                # Additional metadata; existing Flutter summary fields remain.
                "file_name": file_name,
                "has_image": file_name is not None,
                # Full AI report stored as PostgreSQL JSONB. Older records are None.
                "analysis_result": item.analysis_result,
            }
        )

    return formatted_history


def fetch_saved_image(db: Session, user_id: int, classification_id: int):
    """Return an image only when it is saved and owned by this user.

    This is a service helper, not a public API endpoint. The History route
    must authenticate the caller and pass its verified user ID.
    Returns None for unsaved, missing, or other users' records.
    """
    image = (
        db.query(
            ClassificationImage.image_data,
            ClassificationImage.file_name,
            ClassificationImage.mime_type,
        )
        .join(
            ClassificationRecord,
            ClassificationRecord.classification_id
            == ClassificationImage.classification_id,
        )
        .filter(
            ClassificationRecord.classification_id == classification_id,
            ClassificationRecord.user_id == user_id,
            ClassificationRecord.is_saved.is_(True),
        )
        .first()
    )

    if image is None:
        return None

    return {
        "image_bytes": bytes(image.image_data),
        "file_name": image.file_name,
        "mime_type": image.mime_type,
    }
