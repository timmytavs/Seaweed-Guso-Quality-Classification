"""File 94 — TEST-ONLY image eligibility probe for gUSo.

This does NOT modify the running FastAPI application and does NOT train a model.
It uses a separate, already-pretrained CLIP model to compare an image against
seaweed and non-seaweed descriptions. Output is exploratory, not verified
KAPPAPHYCUS identity and not a calibrated probability of being seaweed.

Install once (inside the backend venv):
    python -m pip install "transformers[torch]" pillow

Run from backend root:
    python -m tools.check_image_eligibility "C:\\path\\to\\poor.jpg" "C:\\path\\to\\movie.jpg"

On first run, model weights are downloaded from Hugging Face; later runs can
reuse the cache. This script does not write to PostgreSQL or model weights.
"""

from __future__ import annotations

import argparse
import math
from collections import defaultdict
from functools import lru_cache
from pathlib import Path

import torch
from PIL import Image, UnidentifiedImageError

# Every label belongs to one family. Similar prompt counts prevent score bias.
# The "other_seaweed" family is intentionally distinct from the target.
PROMPTS: tuple[tuple[str, str], ...] = (
    ("kappaphycus", "A close-up photograph of Kappaphycus guso seaweed."),
    ("kappaphycus", "A photograph of harvested Eucheuma cottonii seaweed."),
    ("kappaphycus", "Wet and tangled branching guso seaweed on a plate."),
    ("kappaphycus", "A pile of fresh green Kappaphycus alvarezii seaweed."),
    ("kappaphycus", "A close-up photo of brown or red branching Kappaphycus seaweed."),
    ("other_seaweed", "A close-up photograph of Caulerpa sea grapes seaweed."),
    ("other_seaweed", "A photograph of Sargassum floating marine seaweed."),
    ("other_seaweed", "A close-up photograph of green Ulva sea lettuce."),
    ("other_seaweed", "A photograph of brown Padina marine algae."),
    ("other_seaweed", "A photograph of another type of marine algae or seaweed."),
    ("not_seaweed", "A dramatic movie poster with red and black graphic art."),
    ("not_seaweed", "A movie scene with people and costumes."),
    ("not_seaweed", "An anime illustration or digitally drawn cartoon."),
    ("not_seaweed", "A photo of a person or a human face."),
    ("not_seaweed", "A photograph of a cat or dog."),
    ("not_seaweed", "A photograph of a car on the street."),
    ("not_seaweed", "A photograph of an electronic device or computer."),
    ("not_seaweed", "A photograph of flowers or ordinary land plants."),
    ("not_seaweed", "A picture of a book or printed text."),
    ("not_seaweed", "A photograph of cooked food that contains no seaweed."),
)

MODEL_ID = "openai/clip-vit-base-patch32"


@lru_cache(maxsize=1)
def load_pretrained_validator():
    try:
        from transformers import AutoModelForZeroShotImageClassification, AutoProcessor
    except ImportError as exc:
        raise SystemExit(
            'Missing dependency. Run: python -m pip install "transformers[torch]" pillow'
        ) from exc

    print("Loading pretrained image-check model:", MODEL_ID, flush=True)
    print("First run may download weights. No training is performed.", flush=True)
    processor = AutoProcessor.from_pretrained(MODEL_ID)
    model = AutoModelForZeroShotImageClassification.from_pretrained(MODEL_ID)
    model.eval()
    return processor, model


def summarize_family_logits(values: list[float]) -> dict[str, float]:
    """Average exp-logit evidence within each candidate group.

    Group scores are relative and depend on chosen prompt wording.
    They are not calibrated probabilities of real-world image identity.
    """
    if len(values) != len(PROMPTS):
        raise ValueError("Model output size does not match prompt count")

    by_group: dict[str, list[float]] = defaultdict(list)
    for (group, _), value in zip(PROMPTS, values):
        by_group[group].append(float(value))

    return {
        group: math.log(sum(math.exp(value - max(group_values))
                            for value in group_values))
        + max(group_values) - math.log(len(group_values))
        for group, group_values in by_group.items()
    }


def inspect_image(image_path: Path) -> None:
    if not image_path.is_file():
        print("\nMISSING IMAGE:", image_path)
        return

    try:
        with Image.open(image_path) as input_image:
            image = input_image.convert("RGB")
    except (UnidentifiedImageError, OSError) as exc:
        print("\nINVALID IMAGE:", image_path, exc)
        return

    processor, model = load_pretrained_validator()
    prompts = [text for _, text in PROMPTS]
    inputs = processor(text=prompts, images=image, return_tensors="pt", padding=True)

    with torch.inference_mode():
        logits = model(**inputs).logits_per_image[0].cpu().tolist()

    grouped = summarize_family_logits(logits)
    ranking = sorted(grouped.items(), key=lambda pair: -pair[1])
    margin = ranking[0][1] - ranking[1][1]

    print("\n" + "=" * 72)
    print("IMAGE:", image_path)
    print("Ranking (relative similarity, NOT a verified identity probability):")
    for group, value in ranking:
        print(f"  {group:16} {value:8.3f}")
    print(f"Top-two score margin: {margin:.3f}")

    print("Top matching descriptions:")
    for index in sorted(range(len(logits)), key=lambda i: logits[i], reverse=True)[:5]:
        group, description = PROMPTS[index]
        print(f"  [{group}] {description}")

    print("Exploratory top category:", ranking[0][0])
    print("NOT an automatic acceptance/rejection decision; test on real photos first.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Test-only gUSo image eligibility check")
    parser.add_argument("images", nargs="*", help="Paths to JPG/PNG images")
    args = parser.parse_args()

    if args.images:
        paths = [Path(path).expanduser() for path in args.images]
    else:
        paths = [Path.home() / "Pictures" / f"{label}.jpg"
                 for label in ("fresh", "regular", "poor")]

    for path in paths:
        inspect_image(path)

    print("\nNo changes made to FastAPI, gUSo's quality model, or PostgreSQL.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
