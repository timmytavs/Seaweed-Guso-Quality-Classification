from PIL import Image
import numpy as np


def validate_image(image: Image.Image):

    # Check image size
    width, height = image.size

    if width < 100 or height < 100:
        return {
            "valid": False,
            "reason": "Image resolution is too small."
        }


    # Convert to numpy
    img_array = np.array(image)


    # Check if image has color variation
    color_variance = np.var(img_array)


    if color_variance < 50:
        return {
            "valid": False,
            "reason": "Image does not contain enough visual information."
        }


    return {
        "valid": True,
        "reason": "Image passed validation."
    }