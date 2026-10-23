
from functools import lru_cache
from pathlib import Path

import torch
import torch.nn as nn
from torchvision import models


# File 32 — Quality MobileNetV3 model loader

QUALITY_MODEL_PATH = (
    Path(__file__).resolve().parent
    / "weights"
    / "quality_mobilenetv3_best.pth"
)

QUALITY_CLASSES = (
    "fresh",
    "poor",
    "regular",
)


@lru_cache(maxsize=1)
def load_quality_model():

    if not QUALITY_MODEL_PATH.is_file():
        raise FileNotFoundError(
            f"Quality model not found: {QUALITY_MODEL_PATH}"
        )

    device = torch.device(
        "cuda" if torch.cuda.is_available() else "cpu"
    )

    # Match the model used during training.
    model = models.mobilenet_v3_large(
        weights=None
    )

    # Three quality classifications.
    in_features = model.classifier[3].in_features

    model.classifier[3] = nn.Linear(
        in_features,
        len(QUALITY_CLASSES)
    )

    # Load the trained checkpoint.
    state_dict = torch.load(
        QUALITY_MODEL_PATH,
        map_location="cpu",
        weights_only=True
    )

    model.load_state_dict(state_dict)

    model = model.to(device)
    model.eval()

    return model, device
