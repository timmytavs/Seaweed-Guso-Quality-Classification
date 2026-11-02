"""gUSo quality classification with a preliminary zero-shot seaweed-content guard.

The guard checks whether an image broadly resembles seaweed. It DOES NOT
verify KAPPAPHYCUS species. The existing MobileNetV3 Large checkpoint is still
responsible for Fresh / Regular / Poor quality predictions. No model training.

Testing only: the guard's similarity margin has not been calibrated on a
representative evaluation set. Keep tracking false positives/negatives.
"""

import logging
import math
from collections import defaultdict
from functools import lru_cache

import torch
from fastapi import HTTPException
from fastapi.encoders import jsonable_encoder
from PIL import Image
from sqlalchemy.orm import Session

from app.ml.quality_model_loader import QUALITY_MODEL_VARIANT
from app.ml.quality_predictor import predict_quality
from app.processing.feature_extraction import extract_image_features
from app.database.repository import (
    create_classification_record,
    create_classification_image,
)

logger = logging.getLogger(__name__)

TARGET_SPECIES = "KAPPAPHYCUS"  # User-supplied scope, NOT an AI-verified species.
QUALITY_MODEL_NAME = "mobilenet_v3_large_quality"
CHECKER_MODEL_NAME = "openai/clip-vit-base-patch32"

# Exploratory, intentionally conservative gap between category similarity scores.
# In four initial tests, the actual guso photos had seaweed-minus-nonseaweed
# scores of +6.123, +6.522, +9.284; the movie poster scored -14.272.
# A larger test set is needed before trusting this boundary in production.
REQUIRED_SCORE_GAP = 3.0

# Use precisely the same descriptions as the independently tested File 94.
PROMPTS = (
    ("kappaphycus", "A close-up photograph of Kappaphycus guso seaweed."),
    ("kappaphycus", "A photograph of harvested Eucheuma cottonii seaweed."),
    ("kappaphycus", "Wet and tangled branching guso seaweed on a plate."),
    ("kappaphycus", "A pile of fresh green Kappaphycus alvarezii seaweed."),
    ("kappaphycus", "A close-up photo of brown or red branching Kappaphycus seaweed."),
    ("other_seaweed", "A close-up photograph of Caulerpa sea grapes seaweed."),
    ("other_seaweed", "A photograph of Sargassum floating marine seaweed."),
    ("other_seaweed", "A close-up photograph of green Ulva sea lettuce."),
    ("other_seaweed", "A photograph of brown Padina marine algae."),
    ("other_seaweed", "A photograph of another type of marine algae or seaweed."),
    ("not_seaweed", "A dramatic movie poster with red and black graphic art."),
    ("not_seaweed", "A movie scene with people and costumes."),
    ("not_seaweed", "An anime illustration or digitally drawn cartoon."),
    ("not_seaweed", "A photo of a person or a human face."),
    ("not_seaweed", "A photograph of a cat or dog."),
    ("not_seaweed", "A photograph of a car on the street."),
    ("not_seaweed", "A photograph of an electronic device or computer."),
    ("not_seaweed", "A photograph of flowers or ordinary land plants."),
    ("not_seaweed", "A picture of a book or printed text."),
    ("not_seaweed", "A photograph of cooked food that contains no seaweed."),
)


@lru_cache(maxsize=1)
def _load_checker():
    """Load the pretrained CLIP model once per FastAPI worker, on CPU."""
    from transformers import AutoModelForZeroShotImageClassification, AutoProcessor

    logger.info("Loading zero-shot image eligibility checker: %s", CHECKER_MODEL_NAME)
    processor = AutoProcessor.from_pretrained(CHECKER_MODEL_NAME)
    model = AutoModelForZeroShotImageClassification.from_pretrained(
        CHECKER_MODEL_NAME
    )
    model.eval()
    return processor, model


def _family_scores(logits: list[float]) -> dict[str, float]:
    """Match File 94's per-family log-mean-exp similarity aggregation."""
    if len(logits) != len(PROMPTS):
        raise ValueError("CLIP result does not match the eligibility prompts")

    grouped = defaultdict(list)
    for (family, _), score in zip(PROMPTS, logits):
        grouped[family].append(float(score))

    scores = {}
    for family, values in grouped.items():
        largest = max(values)
        scores[family] = largest + math.log(
            sum(math.exp(v - largest) for v in values)
        ) - math.log(len(values))
    return scores


def _decide_eligibility(scores: dict[str, float]) -> tuple[str, float]:
    """Return (eligible | not_seaweed | uncertain, seaweed-vs-other gap)."""
    seaweed = max(scores["kappaphycus"], scores["other_seaweed"])
    not_seaweed = scores["not_seaweed"]
    gap = seaweed - not_seaweed

    if gap >= REQUIRED_SCORE_GAP:
        return "eligible", gap
    if gap <= -REQUIRED_SCORE_GAP:
        return "not_seaweed", gap
    return "uncertain", gap


def check_image_eligibility(image: Image.Image) -> dict:
    """Screen for broad seaweed content; NOT a species identification."""
    processor, model = _load_checker()
    rgb_image = image.convert("RGB")
    inputs = processor(
        text=[description for _, description in PROMPTS],
        images=rgb_image,
        return_tensors="pt",
        padding=True,
    )
    with torch.inference_mode():
        logits = model(**inputs).logits_per_image[0].cpu().tolist()

    scores = _family_scores(logits)
    status, margin = _decide_eligibility(scores)
    return {"status": status, "margin": round(margin, 3), "scores": scores}


def _unverified_result(status: str) -> dict:
    """API-compatible result; crucially does not claim species or quality."""
    if status == "not_seaweed":
        message = (
            "This image does not appear to contain seaweed. "
            "Please upload a clear photo of KAPPAPHYCUS (guso)."
        )
    else:
        message = (
            "Image content is uncertain. Please upload a clearer photo of "
            "KAPPAPHYCUS (guso) for quality classification."
        )

    return {
        "classification_id": None,
        "species": None,
        "confidence": 0.0,  # Compatibility; NO model confidence was produced.
        "confidence_percentage": 0.0,
        "model_name": "clip_image_eligibility_screen",
        "quality_grade": None,
        "quality_confidence": None,
        "quality_confidence_percentage": None,
        "color": None,
        "image_quality": None,
        "visual_texture": None,
        "image_features": None,
        "message": message,
        "eligibility_status": status,  # Retained if API schema allows extra fields.
    }


def classify_image(
    db: Session,
    image: Image.Image,
    image_bytes: bytes,
    file_name: str,
    mime_type: str,
    user_id: int | None = None,
):
    """Validate broad seaweed content, then predict quality and save draft."""
    if QUALITY_MODEL_VARIANT != "updated":
        raise RuntimeError(
            "The gUSo quality service requires the updated checkpoint. "
            "Set GUSO_QUALITY_MODEL_VARIANT=updated and restart FastAPI."
        )

    # Fail closed: if CLIP cannot be loaded/run, do NOT send the image directly
    # to the quality model and accidentally classify unrelated content.
    try:
        eligibility = check_image_eligibility(image)
    except Exception as exc:
        logger.exception("Image eligibility model failed")
        raise HTTPException(
            status_code=503,
            detail="Image eligibility check is unavailable; no classification was saved.",
        ) from exc

    logger.info(
        "Image eligibility result for %s: %s (score margin %s)",
        file_name, eligibility["status"], eligibility["margin"],
    )
    if eligibility["status"] != "eligible":
        return _unverified_result(eligibility["status"])

    # No species is identified by CLIP or by this three-class quality model.
    quality_prediction = predict_quality(image_bytes)
    quality_grade = quality_prediction["quality_grade"]
    quality_confidence = quality_prediction["quality_confidence"]
    quality_confidence_percentage = round(quality_confidence * 100, 2)

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

    # Preserve the existing database and draft/save/history workflow.
    record = create_classification_record(
        db=db,
        user_id=user_id,
        quality_grade=quality_grade,
        confidence=quality_confidence,  # Quality confidence, not species confidence.
        model_name=QUALITY_MODEL_NAME,
    )
    create_classification_image(
        db=db,
        classification_id=record.classification_id,
        image_bytes=image_bytes,
        file_name=file_name,
        mime_type=mime_type,
    )

    result = {
        "classification_id": record.classification_id,
        "species": TARGET_SPECIES,  # Intended input species, not AI-verified.
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
        "species_source": "user_supplied_target_species",
        "confidence_type": "quality",
        "eligibility_status": "eligible",
        "message": "Classification successful.",
    }

    # Keep full reports in PostgreSQL, even if the API response schema hides
    # optional metadata fields that are not yet declared in Pydantic.
    record.analysis_result = jsonable_encoder(result)
    db.add(record)
    db.commit()
    return result
