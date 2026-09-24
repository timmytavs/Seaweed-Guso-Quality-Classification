from sqlalchemy.orm import Session

from app.database.repository import (
    get_user_history
)



def fetch_history(
    db: Session,
    user_id: int
):

    history = get_user_history(
        db,
        user_id
    )


    formatted_history = []


    for item in history:

        formatted_history.append({

            "id":
                item.classification_id,


            # Temporary:
            # currently stores species
            # inside quality_grade
            "quality_grade":
                item.quality_grade,


            "confidence":
                round(
                    item.confidence_score * 100,
                    2
                ),


            "model":
                item.model_name,


            "date":
                item.classified_at.strftime(
                    "%Y-%m-%d"
                ) if item.classified_at else None

        })


    return formatted_history