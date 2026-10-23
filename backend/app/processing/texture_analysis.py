"""Basic whole-image texture measurements for gUSo.

These values describe visible pixel variation and edges, not biological
surface condition, damage, freshness, or seaweed-only texture.
"""

import cv2
import numpy as np
from PIL import Image


MAX_ANALYSIS_SIZE = 512


def analyze_texture(image: Image.Image) -> dict:
    """Estimate texture variation and edge density from a PIL image.

    Returns basic, heuristic whole-image measurements. Backgrounds,
    lighting, blur, and compression can affect the values.
    """
    if not isinstance(image, Image.Image):
        raise ValueError("A valid PIL image is required.")

    if image.width == 0 or image.height == 0:
        raise ValueError("Image dimensions must be greater than zero.")

    # Analyze a bounded image size to keep processing fast.
    gray_image = image.convert("L")
    gray_image.thumbnail(
        (MAX_ANALYSIS_SIZE, MAX_ANALYSIS_SIZE),
        Image.Resampling.BILINEAR,
    )
    gray = np.asarray(gray_image, dtype=np.uint8)

    # Local standard deviation within a 5x5 window approximates visible
    # intensity changes; it is not a physical texture measurement.
    gray_float = gray.astype(np.float32)
    local_mean = cv2.blur(gray_float, (5, 5))
    local_square_mean = cv2.blur(gray_float * gray_float, (5, 5))
    local_variance = np.maximum(
        local_square_mean - local_mean * local_mean,
        0.0,
    )
    texture_variation = float(np.sqrt(local_variance).mean())

    # Canny highlights intensity boundaries; the percentage represents
    # edge pixels throughout the image, including the background.
    edges = cv2.Canny(gray, threshold1=50, threshold2=150)
    edge_density_percentage = float(np.count_nonzero(edges) / edges.size * 100)

    if texture_variation < 4.0 and edge_density_percentage < 0.8:
        texture_level = "Low"
        texture_description = "Low visible texture or edge detail"
    elif texture_variation >= 12.0 or edge_density_percentage >= 5.0:
        texture_level = "High"
        texture_description = "High visible texture or edge detail"
    else:
        texture_level = "Moderate"
        texture_description = "Moderate visible texture or edge detail"

    return {
        "texture_level": texture_level,
        "texture_description": texture_description,
        "texture_variation": round(texture_variation, 2),
        "edge_density_percentage": round(edge_density_percentage, 2),
        "analysis_scope": "Whole image (including background)",
    }