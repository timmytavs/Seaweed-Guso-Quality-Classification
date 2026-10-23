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
    

def analyze_image_quality(image: Image.Image) -> dict:
    import cv2

    if image is None:
        raise ValueError("Image is required.")

    rgb = np.asarray(image.convert("RGB"))

    height, width = rgb.shape[:2]

    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)

    brightness = float(np.mean(gray))
    contrast = float(np.std(gray))

    sharpness_score = float(
        cv2.Laplacian(gray, cv2.CV_64F).var()
    )

    issues = []

    if width < 224 or height < 224:
        issues.append("Low image resolution")

    if brightness < 50:
        issues.append("Image is too dark")
    elif brightness > 205:
        issues.append("Image is too bright")

    if contrast < 25:
        issues.append("Low image contrast")

    if sharpness_score < 50:
        issues.append("Low edge detail (possibly blurry)")

    if len(issues) == 0:
        image_quality = "Good"
    elif len(issues) == 1:
        image_quality = "Fair"
    else:
        image_quality = "Poor"

    return {
        "image_quality": image_quality,
        "width": width,
        "height": height,
        "brightness": round(brightness, 2),
        "contrast": round(contrast, 2),
        "sharpness_score": round(sharpness_score, 2),
        "issues": issues,
        "summary": (
            "; ".join(issues) + "."
            if issues
            else "Basic image quality checks passed."
        ),
    }
