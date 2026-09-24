from fastapi import (
    APIRouter,
    UploadFile,
    File,
    HTTPException,
    Depends
)

from sqlalchemy.orm import Session

from PIL import Image

from io import BytesIO


from app.database.database import (
    SessionLocal
)


from app.services.classification_service import (
    classify_image
)


from app.schemas.classification import (
    ClassificationResponse
)



router = APIRouter(
    prefix="/classifications",
    tags=["Classification"]
)



# =====================================================
# DATABASE DEPENDENCY
# =====================================================

def get_db():

    db = SessionLocal()

    try:

        yield db

    finally:

        db.close()



# =====================================================
# CLASSIFICATION ENDPOINT
# =====================================================

@router.post(
    "/",
    response_model=ClassificationResponse
)
async def classify_uploaded_image(

    file: UploadFile = File(...),

    db: Session = Depends(get_db)

):


    # ---------------------------------------------
    # CHECK FILE TYPE
    # ---------------------------------------------

    allowed_types = [
        "image/jpeg",
        "image/png"
    ]


    if file.content_type not in allowed_types:

        raise HTTPException(
            status_code=400,
            detail=(
                "Only JPG and PNG images "
                "are allowed."
            )
        )



    # ---------------------------------------------
    # READ IMAGE BYTES
    # ---------------------------------------------

    image_bytes = await file.read()



    # ---------------------------------------------
    # OPEN IMAGE
    # ---------------------------------------------

    try:

        image = Image.open(
            BytesIO(image_bytes)
        ).convert(
            "RGB"
        )


    except Exception:


        raise HTTPException(
            status_code=400,
            detail="Invalid image."
        )



    # ---------------------------------------------
    # CLASSIFY + SAVE
    # ---------------------------------------------

    result = classify_image(

        db=db,

        image=image,

        image_bytes=image_bytes,

        file_name=file.filename,

        mime_type=file.content_type,
        
        user_id=1

    )



    return {

        "filename":
            file.filename,

        "result":
            result

    }