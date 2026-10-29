
"""Load gUSo's MobileNetV3 Small species model and validate class metadata.

This retains the existing MODEL_PATH setting and cached model interface.
It does not change species predictions or the 80% predictor threshold.
"""

from collections.abc import Mapping
from pathlib import Path

import torch
import torch.nn as nn
from torchvision.models import mobilenet_v3_small

from app.core.config import settings


_model = None
_metadata = None

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def _validate_checkpoint(checkpoint):
    """Verify that the saved weights and species label ordering agree."""
    if not isinstance(checkpoint, Mapping):
        raise ValueError(
            "Species checkpoint must contain a dictionary of model data."
        )

    required = ("num_classes", "classes", "class_to_idx", "model_state_dict")
    missing = [key for key in required if key not in checkpoint]
    if missing:
        raise ValueError(
            "Species checkpoint is missing required keys: "
            + ", ".join(missing)
        )

    num_classes = checkpoint["num_classes"]
    classes = checkpoint["classes"]
    class_to_idx = checkpoint["class_to_idx"]
    state_dict = checkpoint["model_state_dict"]

    if type(num_classes) is not int or num_classes < 2:
        raise ValueError("num_classes must be an integer of at least 2.")

    if (
        not isinstance(classes, (list, tuple))
        or len(classes) != num_classes
        or not all(isinstance(label, str) and label for label in classes)
        or len(set(classes)) != len(classes)
    ):
        raise ValueError(
            "The checkpoint's classes must contain one unique string "
            "for each model output."
        )

    if not isinstance(class_to_idx, Mapping):
        raise ValueError("The checkpoint's class_to_idx must be a mapping.")

    expected_mapping = {
        name: index for index, name in enumerate(classes)
    }
    if dict(class_to_idx) != expected_mapping:
        raise ValueError(
            "Species class-label mismatch between classes and class_to_idx. "
            f"classes implies {expected_mapping!r}, but checkpoint stores "
            f"{dict(class_to_idx)!r}. Check the original training script; "
            "do not reorder labels by guessing."
        )

    if (
        not isinstance(state_dict, Mapping)
        or not state_dict
        or not all(
            isinstance(name, str) and isinstance(value, torch.Tensor)
            for name, value in state_dict.items()
        )
    ):
        raise ValueError(
            "model_state_dict must contain PyTorch tensor weights. "
            "Ask for a compatible state_dict checkpoint."
        )

    return num_classes, list(classes), dict(class_to_idx), state_dict


def load_model():
    """Return the cached species model using the configured checkpoint."""
    global _model
    global _metadata

    if _model is not None:
        return _model

    # Keep the existing configured path; do not silently swap checkpoints.
    model_path = Path(settings.MODEL_PATH)

    if not model_path.is_file():
        raise FileNotFoundError(
            f"Trained species model not found: {model_path}"
        )

    print(f"Loading MobileNetV3 species model from: {model_path.resolve()}")

    # Only load weights and simple metadata, not arbitrary pickled objects.
    # If this fails, ask for a safe state_dict export from the trainer.
    checkpoint = torch.load(
        model_path,
        map_location="cpu",
        weights_only=True,
    )

    num_classes, classes, class_to_idx, state_dict = (
        _validate_checkpoint(checkpoint)
    )

    model = mobilenet_v3_small(weights=None)
    input_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(input_features, num_classes)

    try:
        model.load_state_dict(state_dict, strict=True)
    except RuntimeError as exc:
        raise RuntimeError(
            "Species checkpoint weights do not match MobileNetV3 Small. "
            "Confirm architecture and classifier dimensions with the trainer."
        ) from exc

    model = model.to(DEVICE)
    model.eval()

    _metadata = {
        "classes": classes,
        "class_to_idx": class_to_idx,
        "num_classes": num_classes,
        "image_size": checkpoint.get("image_size", 224),
        "validation_accuracy": checkpoint.get("validation_accuracy"),
        "model_name": checkpoint.get("model_name", "mobilenet_v3_small"),
        "checkpoint_path": str(model_path.resolve()),
    }

    _model = model

    print("MobileNetV3 species model loaded successfully.")
    print(f"Device: {DEVICE}")
    print(f"Class mapping: {class_to_idx}")
    print(f"Species checkpoint: {model_path.resolve()}")

    return _model


def get_model_metadata():
    """Return class metadata for the loaded species model."""
    if _model is None:
        load_model()
    return _metadata
