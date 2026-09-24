from fastapi import (
    APIRouter,
    Depends
)

from sqlalchemy.orm import Session


from app.database.database import SessionLocal

from app.services.history_service import (
    fetch_history
)


router = APIRouter(
    prefix="/history",
    tags=["History"]
)



# =============================================
# DATABASE DEPENDENCY
# =============================================

def get_db():

    db = SessionLocal()

    try:
        yield db

    finally:
        db.close()



# =============================================
# GET USER HISTORY
# =============================================

@router.get("/{user_id}")
def get_history(

    user_id: int,

    db: Session = Depends(get_db)

):

    history = fetch_history(
        db,
        user_id
    )


    return {

        "user_id":
            user_id,

        "records":
            history

    }