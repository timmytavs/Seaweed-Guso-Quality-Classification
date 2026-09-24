import torch

from app.ml.model_loader import (
    load_model,
    get_model_metadata,
)


def predict_image(
    image_tensor: torch.Tensor
):

    # -----------------------------------------------------
    # LOAD MODEL + CLASS INFORMATION
    # -----------------------------------------------------

    model = load_model()

    metadata = get_model_metadata()

    classes = metadata["classes"]


    # -----------------------------------------------------
    # VALIDATE INPUT SHAPE
    # -----------------------------------------------------

    # preprocessing.py produces:
    #
    # [3, 224, 224]
    #
    # MobileNetV3 expects:
    #
    # [batch, 3, 224, 224]

    if image_tensor.ndim == 3:

        image_tensor = image_tensor.unsqueeze(0)


    if image_tensor.ndim != 4:

        raise ValueError(
            "Expected image tensor with shape "
            "[3,H,W] or [1,3,H,W]"
        )


    # -----------------------------------------------------
    # MOVE IMAGE TO MODEL DEVICE
    # -----------------------------------------------------

    device = next(
        model.parameters()
    ).device


    image_tensor = image_tensor.to(
        device
    )


    # -----------------------------------------------------
    # RUN PREDICTION
    # -----------------------------------------------------

    model.eval()


    with torch.no_grad():

        outputs = model(
            image_tensor
        )


        probabilities = torch.softmax(
            outputs,
            dim=1
        )


        confidence, predicted_index = torch.max(
            probabilities,
            dim=1
        )


    # -----------------------------------------------------
    # EXTRACT RESULT
    # -----------------------------------------------------

    class_index = predicted_index.item()

    confidence_score = confidence.item()


    # -----------------------------------------------------
    # REJECT LOW CONFIDENCE IMAGES
    # -----------------------------------------------------

    MIN_CONFIDENCE = 0.80


    if confidence_score < MIN_CONFIDENCE:

        return {

            "class_index": None,

            "species": None,

            "confidence":
                round(
                    confidence_score,
                    4
                ),

            "confidence_percentage":
                round(
                    confidence_score * 100,
                    2
                ),

            "message":
                "The uploaded image may not contain seaweed.",

            "model_name":
                metadata["model_name"]
        }


    # -----------------------------------------------------
    # RETURN VALID CLASSIFICATION
    # -----------------------------------------------------

    predicted_class = classes[
        class_index
    ]


    return {

        "class_index":
            class_index,

        "species":
            predicted_class,

        "confidence":
            round(
                confidence_score,
                4
            ),

        "confidence_percentage":
            round(
                confidence_score * 100,
                2
            ),

        "model_name":
            metadata["model_name"]
    }