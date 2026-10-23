"""Simple image-level color analysis for gUSo.

Measures dominant color among sufficiently saturated pixels. This is not
seaweed segmentation; colorful backgrounds may influence the result.
"""

from collections import Counter

import numpy as np
from PIL import Image


COLOR_LABELS = (
    "Brown",
    "Red",
    "Orange",
    "Yellow",
    "Green",
    "Blue",
    "Purple",
    "Pink",
)


def analyze_color(image: Image.Image) -> dict:
    """Return the dominant visible color and distribution of colorful pixels.

    Accepts a Pillow image and does not modify it. Near-white, gray, and
    near-black pixels are omitted to reduce common neutral background effects.
    """
    if not isinstance(image, Image.Image):
        raise TypeError("image must be a PIL.Image.Image")

    # Composite transparent images on white so hidden RGB values do not count.
    rgba = image.convert("RGBA")
    background = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    rgb = Image.alpha_composite(background, rgba).convert("RGB")
    rgb.thumbnail((512, 512), Image.Resampling.LANCZOS)

    hsv = np.asarray(rgb.convert("HSV"), dtype=np.float32)
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    brightness = hsv[:, :, 2] / 255.0

    # Neutral/very dark areas are generally background in product-style photos.
    colored_mask = (saturation >= 0.18) & (brightness >= 0.12)
    colored_count = int(np.count_nonzero(colored_mask))
    total_count = int(colored_mask.size)

    if colored_count < max(20, int(total_count * 0.01)):
        return {
            "dominant_color": "Not determined",
            "dominant_percentage": 0.0,
            "analyzed_pixel_percentage": round(100 * colored_count / total_count, 2),
            "color_distribution": {},
        }

    h = hue[colored_mask]
    s = saturation[colored_mask]
    v = brightness[colored_mask]

    # Rust/brown often overlaps orange and yellow in the HSV hue wheel.
    brown = (h >= 8) & (h < 55) & (s >= 0.26) & (v < 0.70)
    red = (h < 15) | (h >= 345)
    orange = (h >= 15) & (h < 45)
    yellow = (h >= 45) & (h < 70)
    green = (h >= 70) & (h < 170)
    blue = (h >= 170) & (h < 260)
    purple = (h >= 260) & (h < 325)
    pink = (h >= 325) & (h < 345)

    labels = np.select(
        [brown, red, orange, yellow, green, blue, purple, pink],
        COLOR_LABELS,
        default="Other",
    )
    counts = Counter(labels.tolist())
    distribution = {
        label: round(100 * count / colored_count, 2)
        for label, count in counts.most_common()
    }
    dominant = counts.most_common(1)[0][0]

    return {
        "dominant_color": dominant,
        "dominant_percentage": distribution[dominant],
        "analyzed_pixel_percentage": round(100 * colored_count / total_count, 2),
        "color_distribution": distribution,
    }
