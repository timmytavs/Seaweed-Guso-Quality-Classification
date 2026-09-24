from PIL import Image
from sqlalchemy.orm import Session

from app.processing.preprocessing import (
    preprocess_image
)

from app.ml.predictor import (
    predict_image
)

from app.database.repository import (
    create_classification_record,
    create_classification_image
)


def classify_image(
    db: Session,
    image: Image.Image,
    image_bytes: bytes,
    file_name: str,
    mime_type: str,
    user_id: int | None = None
):

    """
    Current classification workflow.

    Uploaded Image
          |
          ↓
    Preprocessing
          |
          ↓
    MobileNetV3 Species Prediction
          |
          ↓
    Save Database
          |
          ↓
    Return Result
    """


    # =============================================
    # IMAGE PREPROCESSING
    # =============================================

    image_tensor = preprocess_image(
        image
    )


    # =============================================
    # AI PREDICTION
    # =============================================

    prediction = predict_image(
        image_tensor
    )


    # =============================================
    # CHECK IF IMAGE WAS REJECTED
    # =============================================

    if prediction.get("species") is None:

        return {
            "classification_id": None,

            "species": None,

            "confidence":
                prediction["confidence"],

            "confidence_percentage":
                prediction["confidence_percentage"],

            "model_name":
                prediction["model_name"],

            "message":
                prediction.get(
                    "message",
                    "The uploaded image could not be classified."
                )
        }


    # =============================================
    # SAVE CLASSIFICATION RECORD
    # =============================================

    record = create_classification_record(

        db=db,

        user_id=user_id,

        # The real quality model does not exist yet.
        quality_grade="Pending",

        confidence=prediction["confidence"],

        model_name=prediction["model_name"]
    )


    # =============================================
    # SAVE IMAGE
    # =============================================

    create_classification_image(

        db=db,

        classification_id=
            record.classification_id,

        image_bytes=image_bytes,

        file_name=file_name,

        mime_type=mime_type
    )


    # =============================================
    # RESPONSE
    # =============================================

    return {
        "classification_id":
            record.classification_id,

        "species":
            prediction["species"],

        "confidence":
            prediction["confidence"],

        "confidence_percentage":
            prediction["confidence_percentage"],

        "model_name":
            prediction["model_name"],

        "message":
            prediction.get(
                "message",
                "Classification successful."
            )
    }