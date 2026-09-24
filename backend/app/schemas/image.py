from datetime import datetime

from pydantic import BaseModel



class ImageResponse(BaseModel):

    image_id: int

    file_name: str

    mime_type: str

    uploaded_at: datetime


    class Config:

        from_attributes = True



class ImageUploadResponse(BaseModel):

    file_name: str

    mime_type: str

    message: str