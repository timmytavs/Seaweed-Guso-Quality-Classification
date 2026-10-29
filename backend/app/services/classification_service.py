
"""Run gUSo quality-only analysis for user-submitted KAPPAPHYCUS photos.

The updated MobileNetV3 Large model predicts Fresh, Regular, or Poor.
It does NOT identify or verify the seaweed species.
"""

import logging

from fastapi.encoders import jsonable_encoder
from PIL import Image
from sqlalchemy.orm import Session

from app.processing.feature_extraction import extract_image_features
from app.ml.quality_model_loader import QUALITY_MODEL_VARIANT
from app.ml.quality_predictor import predict_quality
from app.database.repository import (
    create_classification_record,
    create_classification_image,
)

logger = logging.getLogger(__name__)

# KAPPAPHYCUS is the intended input, not a detected species.
TARGET_SPECIES = "KAPPAPHYCUS"
QUALITY_MODEL_NAME = "mobilenet_v3_large_quality"


def classify_image(
    db: Session,
    image: Image.Image,
    image_bytes: bytes,
    file_name: str,
    mime_type: str,
    user_id: int | None = None,
):
    """Predict quality without the old seven-species gate."""

    if QUALITY_MODEL_VARIANT != "updated":
        raise RuntimeError(
            "The gUSo quality-only service requires the updated checkpoint. "
            "Set GUSO_QUALITY_MODEL_VARIANT=updated and restart FastAPI."
        )

    # Run the updated quality model directly.
    quality_prediction = predict_quality(image_bytes)

    quality_grade = quality_prediction["quality_grade"]
    quality_confidence = quality_prediction["quality_confidence"]
    quality_confidence_percentage = round(
        quality_confidence * 100, 2
    )

    # Optional photographic image features.
    image_features = None
    dominant_color = None
    photographic_quality = None
    visual_texture = None

    try:
        image_features = extract_image_features(image)

        dominant_color = (
            image_features["color"]["dominant_color"]
        )

        photographic_quality = (
            image_features["image_quality"]["image_quality"]
        )

        visual_texture = (
            image_features["texture"]["texture_description"]
        )

    except Exception:
        logger.exception(
            "Optional image feature extraction failed"
        )

    # Confidence now comes from the quality model,
    # not from the previous species classifier.
    record = create_classification_record(
        db=db,
        user_id=user_id,
        quality_grade=quality_grade,
        confidence=quality_confidence,
        model_name=QUALITY_MODEL_NAME,
    )

    # Preserve original-image storage.
    create_classification_image(
        db=db,
        classification_id=record.classification_id,
        image_bytes=image_bytes,
        file_name=file_name,
        mime_type=mime_type,
    )

    # Maintain compatibility with existing API and Flutter fields.
    result = {
        "classification_id": record.classification_id,
        "species": TARGET_SPECIES,
        "confidence": quality_confidence,
        "confidence_percentage": quality_confidence_percentage,
        "model_name": QUALITY_MODEL_NAME,
        "quality_grade": quality_grade,
        "quality_confidence": quality_confidence,
        "quality_confidence_percentage": quality_confidence_percentage,
        "color": dominant_color,
        "image_quality": photographic_quality,
        "visual_texture": visual_texture,
        "image_features": image_features,
        "species_verified": False,
        "species_source": "assumed_kappaphycus_input",
        "confidence_type": "quality",
        "message": (
            "Quality-only prediction for a user-submitted "
            "KAPPAPHYCUS image. Species identity was not "
            "verified by AI. The displayed confidence is "
            "the quality-model confidence, not species "
            "confidence."
        ),
    }

    # Preserve the full classification report in PostgreSQL.
    # Records remain drafts until the user presses Save.
    record.analysis_result = jsonable_encoder(result)

    db.add(record)
    db.commit()

    return result
