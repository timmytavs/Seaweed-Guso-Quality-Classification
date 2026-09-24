from typing import Optional

from pydantic import BaseModel



class ClassificationResult(BaseModel):

    classification_id: Optional[int] = None

    species: Optional[str] = None

    confidence: float

    confidence_percentage: float

    model_name: str

    message: Optional[str] = None



class ClassificationResponse(BaseModel):

    filename: str

    result: ClassificationResult