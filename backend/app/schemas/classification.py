from typing import Any, Optional

from pydantic import BaseModel


class ClassificationResult(BaseModel):
    classification_id: Optional[int] = None
    species: Optional[str] = None
    confidence: float
    confidence_percentage: float
    model_name: str

    quality_grade: Optional[str] = None
    quality_confidence: Optional[float] = None
    quality_confidence_percentage: Optional[float] = None

    color: Optional[str] = None
    image_quality: Optional[str] = None
    visual_texture: Optional[str] = None
    image_features: Optional[dict[str, Any]] = None

    message: Optional[str] = None


class ClassificationResponse(BaseModel):
    filename: str
    result: ClassificationResult