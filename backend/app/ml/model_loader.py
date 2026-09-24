from pathlib import Path

import torch
import torch.nn as nn

from torchvision.models import mobilenet_v3_small

from app.core.config import settings


# ---------------------------------------------------------
# CACHE
# ---------------------------------------------------------

_model = None
_metadata = None


# ---------------------------------------------------------
# DEVICE
# ---------------------------------------------------------

DEVICE = torch.device(
    "cuda"
    if torch.cuda.is_available()
    else "cpu"
)


# ---------------------------------------------------------
# LOAD MODEL
# ---------------------------------------------------------

def load_model():

    global _model
    global _metadata


    # Reuse already-loaded model
    if _model is not None:
        return _model


    model_path = Path(
        settings.MODEL_PATH
    )


    if not model_path.exists():

        raise FileNotFoundError(
            f"Trained model not found: "
            f"{model_path}"
        )


    print(
        f"Loading MobileNetV3 model from: "
        f"{model_path}"
    )


    checkpoint = torch.load(
        model_path,
        map_location=DEVICE,
        weights_only=False
    )


    # -----------------------------------------------------
    # READ CHECKPOINT INFORMATION
    # -----------------------------------------------------

    num_classes = checkpoint[
        "num_classes"
    ]

    classes = checkpoint[
        "classes"
    ]

    class_to_idx = checkpoint[
        "class_to_idx"
    ]


    # -----------------------------------------------------
    # CREATE MOBILENETV3
    # -----------------------------------------------------

    model = mobilenet_v3_small(
        weights=None
    )


    input_features = (
        model.classifier[3].in_features
    )


    # Replace ImageNet's 1000-class output
    # with your 7 seaweed classes.
    model.classifier[3] = nn.Linear(
        input_features,
        num_classes
    )


    # -----------------------------------------------------
    # LOAD TRAINED WEIGHTS
    # -----------------------------------------------------

    model.load_state_dict(
        checkpoint[
            "model_state_dict"
        ]
    )


    model = model.to(
        DEVICE
    )


    model.eval()


    # -----------------------------------------------------
    # STORE METADATA
    # -----------------------------------------------------

    _metadata = {

        "classes":
            classes,

        "class_to_idx":
            class_to_idx,

        "num_classes":
            num_classes,

        "image_size":
            checkpoint.get(
                "image_size",
                224
            ),

        "validation_accuracy":
            checkpoint.get(
                "validation_accuracy"
            ),

        "model_name":
            checkpoint.get(
                "model_name",
                "mobilenet_v3_small"
            )
    }


    _model = model


    print(
        "MobileNetV3 model loaded successfully."
    )

    print(
        f"Device: {DEVICE}"
    )

    print(
        f"Classes: {classes}"
    )


    return _model


# ---------------------------------------------------------
# GET MODEL METADATA
# ---------------------------------------------------------

def get_model_metadata():

    if _model is None:
        load_model()

    return _metadata