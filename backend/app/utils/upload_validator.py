from fastapi import UploadFile, HTTPException


ALLOWED_IMAGE_TYPES = [
    "image/jpeg",
    "image/png",
    "image/jpg"
]


def validate_image(
    image: UploadFile
):

    if image.content_type not in ALLOWED_IMAGE_TYPES:

        raise HTTPException(
            status_code=400,
            detail="Only JPG and PNG images are allowed"
        )

    return True