
"""Load the active gUSo seaweed-quality model (current or updated).

The original checkpoint remains the default. Set
GUSO_QUALITY_MODEL_VARIANT=updated to test the partner's new checkpoint.
Restart FastAPI after changing the setting because the model is cached.
"""

import logging
import os
from functools import lru_cache
from pathlib import Path

import torch
import torch.nn as nn
from dotenv import load_dotenv
from torchvision import models


logger = logging.getLogger(__name__)

# Resolve backend/.env independently of the app import order.
load_dotenv(Path(__file__).resolve().parents[2] / ".env")

WEIGHTS_DIR = Path(__file__).resolve().parent / "weights"

QUALITY_CLASSES = (
    "fresh",
    "poor",
    "regular",
)

QUALITY_MODEL_VARIANT = os.getenv(
    "GUSO_QUALITY_MODEL_VARIANT", "current"
).strip().lower()


def _resolve_model_path() -> Path:
    filenames = {
        "current": "quality_mobilenetv3_best.pth",
        "updated": "quality_mobilenetv3_updated.pth",
    }
    filename = filenames.get(QUALITY_MODEL_VARIANT)
    if filename is None:
        raise ValueError(
            "GUSO_QUALITY_MODEL_VARIANT must be 'current' or 'updated'."
        )
    return WEIGHTS_DIR / filename


# Retain this constant for other existing code that imports the model path.
QUALITY_MODEL_PATH = _resolve_model_path()


def _check_class_mapping(checkpoint: dict) -> None:
    """Reject an explicitly supplied class mapping that doesn't match the API."""
    metadata = checkpoint.get("metadata")
    sources = [checkpoint]
    if isinstance(metadata, dict):
        sources.append(metadata)

    for source in sources:
        for name in ("class_names", "classes"):
            value = source.get(name)
            if isinstance(value, (list, tuple)) and tuple(value) != QUALITY_CLASSES:
                raise ValueError(
                    f"Checkpoint {name} {list(value)!r} does not match "
                    f"the backend class order {list(QUALITY_CLASSES)!r}."
                )

        mapping = source.get("class_to_idx")
        if isinstance(mapping, dict):
            expected = {name: i for i, name in enumerate(QUALITY_CLASSES)}
            if mapping != expected:
                raise ValueError(
                    f"Checkpoint class_to_idx {mapping!r} does not match "
                    f"the backend mapping {expected!r}."
                )

        count = source.get("num_classes")
        if isinstance(count, int) and count != len(QUALITY_CLASSES):
            raise ValueError(
                f"Checkpoint has {count} classes; expected {len(QUALITY_CLASSES)}."
            )


def _extract_state_dict(checkpoint):
    """Support bare state_dict files and common training checkpoint wrappers."""
    if not isinstance(checkpoint, dict):
        raise ValueError(
            "Unsupported checkpoint format. Ask for a PyTorch state_dict export."
        )

    _check_class_mapping(checkpoint)

    for key in ("model_state_dict", "state_dict"):
        value = checkpoint.get(key)
        if isinstance(value, dict):
            state_dict = value
            break
    else:
        state_dict = checkpoint

    if not state_dict or not all(
        isinstance(key, str) and isinstance(value, torch.Tensor)
        for key, value in state_dict.items()
    ):
        raise ValueError(
            "No valid model state_dict found in the checkpoint. "
            "Ask your partner to export the trained model weights."
        )

    # Handle DataParallel model exports without relaxing strict shape checks.
    if all(key.startswith("module.") for key in state_dict):
        state_dict = {
            key.removeprefix("module."): value
            for key, value in state_dict.items()
        }
    return state_dict


@lru_cache(maxsize=1)
def load_quality_model():
    """Load MobileNetV3 Large and return (model, device)."""
    if not QUALITY_MODEL_PATH.is_file():
        raise FileNotFoundError(
            f"Quality model not found: {QUALITY_MODEL_PATH}. "
            "Keep the current checkpoint or copy the updated file into weights/."
        )

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = models.mobilenet_v3_large(weights=None)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, len(QUALITY_CLASSES))

    # Never unpickle executable Python objects from third-party checkpoints.
    checkpoint = torch.load(
        QUALITY_MODEL_PATH,
        map_location="cpu",
        weights_only=True,
    )
    state_dict = _extract_state_dict(checkpoint)

    try:
        model.load_state_dict(state_dict, strict=True)
    except RuntimeError as exc:
        raise RuntimeError(
            "The selected quality checkpoint does not match MobileNetV3 Large "
            "with three classes. Verify your partner's training architecture "
            "and checkpoint before changing the active model."
        ) from exc

    model = model.to(device)
    model.eval()
    logger.info(
        "Loaded gUSo quality checkpoint %s (variant=%s, device=%s)",
        QUALITY_MODEL_PATH.name,
        QUALITY_MODEL_VARIANT,
        device,
    )
    return model, device
