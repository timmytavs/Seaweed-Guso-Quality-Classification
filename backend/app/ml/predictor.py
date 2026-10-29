
"""gUSo species prediction with safe confidence-gate diagnostics.

Keep the existing 80% acceptance rule. A low species confidence is not
proof that an image contains no seaweed. Call predict_image(..., diagnostic=True)
from a local test to inspect the model's unfiltered class probabilities.
"""

import logging

import torch

from app.ml.model_loader import load_model, get_model_metadata

logger = logging.getLogger(__name__)

# Preserve the existing production species acceptance threshold.
MIN_SPECIES_CONFIDENCE = 0.80


def predict_image(
    image_tensor: torch.Tensor,
    *,
    diagnostic: bool = False,
) -> dict:
    """Classify one image and report whether species confidence is sufficient.

    Normal calls preserve the response fields used by classification_service.
    With diagnostic=True, extra fields reveal the model's candidate classes
    without bypassing the acceptance rule or saving a database record.
    """
    model = load_model()
    metadata = get_model_metadata()
    classes = metadata["classes"]

    if (
        not isinstance(classes, (list, tuple))
        or not classes
        or not all(isinstance(name, str) and name for name in classes)
    ):
        raise ValueError("The species model's class metadata is invalid.")

    if not isinstance(image_tensor, torch.Tensor):
        raise TypeError("image_tensor must be a torch.Tensor.")

    # Preprocessing normally produces [3, H, W]; the model uses [1, 3, H, W].
    if image_tensor.ndim == 3:
        image_tensor = image_tensor.unsqueeze(0)

    if (
        image_tensor.ndim != 4
        or image_tensor.shape[0] != 1
        or image_tensor.shape[1] != 3
    ):
        raise ValueError("Expected image tensor [3,H,W] or [1,3,H,W].")

    device = next(model.parameters()).device
    image_tensor = image_tensor.to(device)
    model.eval()

    with torch.inference_mode():
        outputs = model(image_tensor)
        if (
            outputs.ndim != 2
            or outputs.shape[0] != 1
            or outputs.shape[1] != len(classes)
        ):
            raise ValueError(
                "Species model output dimensions do not match the class mapping."
            )

        probabilities = torch.softmax(outputs, dim=1)
        if not bool(torch.isfinite(probabilities).all().item()):
            raise ValueError("Species model returned non-finite probabilities.")

        confidence, predicted_index = probabilities.max(dim=1)
        class_index = int(predicted_index.item())
        confidence_score = float(confidence.item())

    candidate_species = classes[class_index]
    accepted = confidence_score >= MIN_SPECIES_CONFIDENCE
    confidence_percentage = round(confidence_score * 100, 2)

    result = {
        "class_index": class_index if accepted else None,
        "species": candidate_species if accepted else None,
        "confidence": round(confidence_score, 4),
        "confidence_percentage": confidence_percentage,
        "model_name": metadata["model_name"],
    }

    if not accepted:
        # The old message said the image might not contain seaweed. That is
        # not something a species-only softmax confidence can establish.
        result["message"] = (
            f"Species identification is uncertain ({confidence_percentage:.2f}% "
            f"confidence; {MIN_SPECIES_CONFIDENCE * 100:.0f}% required). "
            "This does not prove the image is not seaweed. "
            "Try a clearer photo or review the species model."
        )
        logger.info(
            "Species prediction not accepted: candidate=%s confidence=%.2f%% "
            "minimum=%.0f%%",
            candidate_species,
            confidence_score * 100,
            MIN_SPECIES_CONFIDENCE * 100,
        )

    if diagnostic:
        # Diagnostic fields are used only in explicit local tests; they are
        # NOT an accepted species result for the main FastAPI pipeline.
        result["accepted"] = accepted
        result["candidate_species"] = candidate_species
        result["candidate_class_index"] = class_index
        result["minimum_species_confidence"] = MIN_SPECIES_CONFIDENCE
        result["class_probabilities"] = [
            {
                "class_index": i,
                "species": name,
                "probability": round(float(probabilities[0, i].item()), 4),
            }
            for i, name in enumerate(classes)
        ]

    return result
