
"""Run gUSo species, quality, and image-feature analysis."""

import logging

from fastapi.encoders import jsonable_encoder
from PIL import Image
from sqlalchemy.orm import Session

from app.processing.preprocessing import preprocess_image
from app.processing.feature_extraction import extract_image_features
from app.ml.predictor import predict_image
from app.ml.quality_predictor import predict_quality
from app.database.repository import (
    create_classification_record,
    create_classification_image,
)

logger = logging.getLogger(__name__)


def classify_image(
    db: Session,
    image: Image.Image,
    image_bytes: bytes,
    file_name: str,
    mime_type: str,
    user_id: int | None = None,
):
    """Classify accepted seaweed images and return available measurements."""

    # Preserve the established MobileNetV3 Small species workflow.
    image_tensor = preprocess_image(image)
    prediction = predict_image(image_tensor)

    # Images rejected by the species stage must not receive a quality grade
    # or create a classification record.
    if prediction.get("species") is None:
        return {
            "classification_id": None,
            "species": None,
            "confidence": prediction["confidence"],
            "confidence_percentage": prediction["confidence_percentage"],
            "model_name": prediction["model_name"],
            "quality_grade": None,
            "quality_confidence": None,
            "quality_confidence_percentage": None,
            "color": None,
            "image_quality": None,
            "visual_texture": None,
            "image_features": None,
            "message": prediction.get(
                "message", "The uploaded image could not be classified."
            ),
        }

    # MobileNetV3 Large performs the separate seaweed-quality prediction.
    quality_prediction = predict_quality(image_bytes)
    quality_grade = quality_prediction["quality_grade"]
    quality_confidence = quality_prediction["quality_confidence"]

    # Image-level processing measures color, photographic quality, and edge
    # detail. It is NOT seaweed segmentation or a biological health test.
    # The auxiliary measurements must not prevent the trained models from
    # producing a result if one of the heuristics fails on an unusual image.
    image_features = None
    dominant_color = None
    photographic_quality = None
    visual_texture = None

    try:
        image_features = extract_image_features(image)
        dominant_color = image_features["color"]["dominant_color"]
        photographic_quality = image_features["image_quality"]["image_quality"]
        visual_texture = image_features["texture"]["texture_description"]
    except Exception:
        logger.exception("Optional image feature extraction failed")

    # Keep the existing database operations unchanged. The database records
    # the actual quality class, while confidence_score remains species-only.
    record = create_classification_record(
        db=db,
        user_id=user_id,
        quality_grade=quality_grade,
        confidence=prediction["confidence"],
        model_name=prediction["model_name"],
    )

    create_classification_image(
        db=db,
        classification_id=record.classification_id,
        image_bytes=image_bytes,
        file_name=file_name,
        mime_type=mime_type,
    )

    # Preserve every established API field; add the optional image-level
    # measurements for the updated schema and Flutter result screen.
    result = {
        "classification_id": record.classification_id,
        "species": prediction["species"],
        "confidence": prediction["confidence"],
        "confidence_percentage": prediction["confidence_percentage"],
        "model_name": prediction["model_name"],
        "quality_grade": quality_grade,
        "quality_confidence": quality_confidence,
        "quality_confidence_percentage": round(quality_confidence * 100, 2),
        "color": dominant_color,
        "image_quality": photographic_quality,
        "visual_texture": visual_texture,
        "image_features": image_features,
        "message": prediction.get("message", "Classification successful."),
    }

    # Store the same actual AI report that Flutter receives. The record
    # remains a draft (is_saved=False) until the user presses Save.
    # jsonable_encoder ensures the value fits PostgreSQL's JSONB column.
    record.analysis_result = jsonable_encoder(result)
    db.add(record)
    db.commit()

    return result
