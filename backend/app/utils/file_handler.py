import os
import uuid

from fastapi import UploadFile


UPLOAD_DIRECTORY = "uploads"


def save_image(
    image: UploadFile
):

    if not os.path.exists(UPLOAD_DIRECTORY):

        os.makedirs(
            UPLOAD_DIRECTORY
        )


    file_extension = image.filename.split(".")[-1]


    filename = (
        f"{uuid.uuid4()}."
        f"{file_extension}"
    )


    file_path = os.path.join(
        UPLOAD_DIRECTORY,
        filename
    )


    with open(
        file_path,
        "wb"
    ) as buffer:

        buffer.write(
            image.file.read()
        )


    return file_path