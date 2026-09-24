from sqlalchemy.orm import Session

from app.database.models import (
    ClassificationRecord,
    ClassificationImage
)



# =====================================================
# SAVE CLASSIFICATION RESULT
# =====================================================

def create_classification_record(
    db: Session,
    user_id: int,
    quality_grade: str,
    confidence: float,
    model_name: str
):


    record = ClassificationRecord(

        user_id=user_id,

        # Temporary storage:
        # Until quality model exists,
        # we store detected species here.
        quality_grade=quality_grade,

        confidence_score=confidence,

        model_name=model_name
    )


    db.add(record)

    db.commit()

    db.refresh(record)


    return record



# =====================================================
# SAVE IMAGE
# =====================================================

def create_classification_image(
    db: Session,
    classification_id: int,
    image_bytes: bytes,
    file_name: str,
    mime_type: str
):


    image = ClassificationImage(

        classification_id=classification_id,

        image_data=image_bytes,

        file_name=file_name,

        mime_type=mime_type
    )


    db.add(image)

    db.commit()

    db.refresh(image)


    return image



# =====================================================
# GET USER HISTORY
# =====================================================

def get_user_history(
    db: Session,
    user_id: int
):

    records = (
        db.query(
            ClassificationRecord
        )
        .filter(
            ClassificationRecord.user_id == user_id
        )
        .order_by(
            ClassificationRecord.classified_at.desc()
        )
        .all()
    )


    return records