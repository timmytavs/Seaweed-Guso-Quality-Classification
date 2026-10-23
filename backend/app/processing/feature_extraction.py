
"""Combine image-processing features for gUSo."""

from PIL import Image

from app.processing.color_analysis import analyze_color
from app.processing.image_quality_validator import analyze_image_quality
from app.processing.texture_analysis import analyze_texture


def extract_image_features(image: Image.Image) -> dict:

    if not isinstance(image, Image.Image):
        raise TypeError("image must be a PIL.Image.Image")

    if image.width < 1 or image.height < 1:
        raise ValueError(
            "Image dimensions must be greater than zero."
        )

    # Analyze the uploaded image.
    color_result = analyze_color(image)

    image_quality_result = analyze_image_quality(image)

    texture_result = analyze_texture(image)

    # Combine the results.
    return {
        "color": color_result,
        "image_quality": image_quality_result,
        "texture": texture_result,
    }
