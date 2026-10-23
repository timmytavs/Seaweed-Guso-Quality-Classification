
from io import BytesIO

import torch
from PIL import Image, UnidentifiedImageError
from torchvision import transforms

from app.ml.quality_model_loader import (
    load_quality_model,
    QUALITY_CLASSES,
)


# =====================================================
# FILE 33 — QUALITY PREDICTOR
# MobileNetV3 Large
# =====================================================


# Same preprocessing as the training validation set.
quality_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    ),
])


# =====================================================
# PREDICT SEAWEED QUALITY
# =====================================================

def predict_quality(image_bytes: bytes) -> dict:

    if not image_bytes:
        raise ValueError("Image data is empty.")

    # ---------------------------------------------
    # READ AND PREPROCESS IMAGE
    # ---------------------------------------------

    try:
        with Image.open(BytesIO(image_bytes)) as image:
            rgb_image = image.convert("RGB")

            image_tensor = (
                quality_transform(rgb_image)
                .unsqueeze(0)
            )

    except (UnidentifiedImageError, OSError) as exc:
        raise ValueError(
            "Unable to read the uploaded image."
        ) from exc

    # ---------------------------------------------
    # LOAD TRAINED QUALITY MODEL
    # ---------------------------------------------

    model, device = load_quality_model()

    image_tensor = image_tensor.to(device)

    # ---------------------------------------------
    # RUN MODEL INFERENCE
    # ---------------------------------------------

    with torch.inference_mode():

        outputs = model(image_tensor)

        probabilities = torch.softmax(
            outputs,
            dim=1
        )

        confidence, predicted_index = torch.max(
            probabilities,
            dim=1
        )

    # ---------------------------------------------
    # FORMAT PREDICTION
    # ---------------------------------------------

    index = int(predicted_index.item())

    quality_grade = QUALITY_CLASSES[index].capitalize()

    quality_confidence = round(
        float(confidence.item()),
        4
    )

    return {
        "quality_grade": quality_grade,
        "quality_confidence": quality_confidence,
    }
