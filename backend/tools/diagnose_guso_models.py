
"""gUSo species and quality model diagnostics (read-only).

Run from the backend/ directory, with the virtual environment activated:
    $env:GUSO_QUALITY_MODEL_VARIANT="updated"
    python -m tools.diagnose_guso_models

Alternatively specify the folder containing fresh.jpg, regular.jpg, poor.jpg:
    python -m tools.diagnose_guso_models "C:\\Users\\Administrator\\Pictures"

This script never saves classifications or alters model weights/database records.
"""

import hashlib
import sys
from pathlib import Path

import torch
from PIL import Image

from app.ml.quality_model_loader import (
    QUALITY_CLASSES,
    QUALITY_MODEL_PATH,
    WEIGHTS_DIR,
    load_quality_model,
)
from app.ml.quality_predictor import quality_transform
from app.ml.predictor import predict_image
from app.processing.preprocessing import preprocess_image


IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")
EXPECTED_CATEGORIES = ("fresh", "regular", "poor")


def find_image(folder: Path, category: str) -> Path | None:
    for suffix in IMAGE_SUFFIXES:
        candidate = folder / f"{category}{suffix}"
        if candidate.is_file():
            return candidate
    return None


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def report_checkpoints() -> None:
    print("\n=== QUALITY CHECKPOINT COMPARISON ===", flush=True)
    print(f"Active: {QUALITY_MODEL_PATH}", flush=True)

    original = WEIGHTS_DIR / "quality_mobilenetv3_best.pth"
    updated = WEIGHTS_DIR / "quality_mobilenetv3_updated.pth"
    hashes = {}

    for file in (original, updated):
        if not file.is_file():
            print(f"{file.name}: NOT FOUND", flush=True)
            continue

        fingerprint = sha256_file(file)
        hashes[file.name] = fingerprint
        print(f"{file.name}: {file.stat().st_size:,} bytes", flush=True)
        print(f"SHA256: {fingerprint}", flush=True)

    if len(hashes) == 2:
        same = hashes[original.name] == hashes[updated.name]
        print(f"Files contain identical bytes: {same}", flush=True)

        if same:
            print(
                "NOTE: These filenames do not represent different models. "
                "Check whether best.pth was replaced before it was copied.",
                flush=True,
            )


def predict_quality_with_probabilities(model, device, image: Image.Image):
    tensor = quality_transform(image).unsqueeze(0).to(device)

    with torch.inference_mode():
        logits = model(tensor)

        if tuple(logits.shape) != (1, len(QUALITY_CLASSES)):
            raise ValueError(
                f"Unexpected quality output shape: {tuple(logits.shape)}"
            )

        values = torch.softmax(logits, dim=1)[0]

        if not bool(torch.isfinite(values).all().item()):
            raise ValueError("Non-finite model probabilities")

        probabilities = values.cpu().tolist()

    print("Quality class probabilities:", flush=True)

    for index, (name, value) in enumerate(
        zip(QUALITY_CLASSES, probabilities)
    ):
        print(f"  [{index}] {name:<8} {value * 100:7.2f}%", flush=True)

    winning = max(
        range(len(probabilities)),
        key=probabilities.__getitem__,
    )

    return QUALITY_CLASSES[winning], probabilities[winning]


def report_species(image: Image.Image) -> None:
    try:
        result = predict_image(
            preprocess_image(image),
            diagnostic=True,
        )
    except Exception as error:
        print(
            f"Species diagnostic failed: "
            f"{type(error).__name__}: {error}",
            flush=True,
        )
        return

    print(
        f"Species candidate: {result.get('candidate_species')}",
        flush=True,
    )
    print(
        f"Species confidence: {result.get('confidence_percentage')}%",
        flush=True,
    )
    print(
        f"Accepted by species gate: {result.get('accepted')}",
        flush=True,
    )


def main() -> int:
    print(
        "=== gUSo DUAL-MODEL DIAGNOSTIC STARTED ===",
        flush=True,
    )

    folder = (
        Path(sys.argv[1]).expanduser()
        if len(sys.argv) > 1
        else Path.home() / "Pictures"
    )

    print(f"Image folder: {folder}", flush=True)

    if not folder.is_dir():
        print("ERROR: Image folder does not exist.", flush=True)
        return 1

    report_checkpoints()

    print("\nLoading selected quality model...", flush=True)

    try:
        model, device = load_quality_model()
    except Exception as error:
        print(
            f"ERROR loading model: "
            f"{type(error).__name__}: {error}",
            flush=True,
        )
        return 1

    print(f"Model device: {device}", flush=True)
    print(
        f"Backend quality class order: {QUALITY_CLASSES}",
        flush=True,
    )
    print(
        "Reminder: Filename labels are expectations, "
        "not independently verified ground truth.",
        flush=True,
    )

    found = 0
    correct = 0

    for expected in EXPECTED_CATEGORIES:
        print(
            f"\n=== TEST IMAGE: {expected.upper()} ===",
            flush=True,
        )

        path = find_image(folder, expected)

        if path is None:
            print(
                f"Missing: {expected}.jpg / .jpeg / .png",
                flush=True,
            )
            continue

        found += 1
        print(f"File: {path}", flush=True)

        try:
            with Image.open(path) as source:
                image = source.convert("RGB")

            label, confidence = predict_quality_with_probabilities(
                model,
                device,
                image,
            )
        except Exception as error:
            print(
                f"Quality test failed: "
                f"{type(error).__name__}: {error}",
                flush=True,
            )
            continue

        match = label == expected
        correct += int(match)

        print(
            f"Quality prediction: {label} "
            f"({confidence * 100:.2f}%)",
            flush=True,
        )
        print(
            f"Matches expected filename: {match}",
            flush=True,
        )

        report_species(image)

    print(
        f"\n=== FINISHED: {found} image file(s) found; "
        f"{correct} matched expected quality labels ===",
        flush=True,
    )
    print(
        "No model weights or PostgreSQL data were modified.",
        flush=True,
    )

    return 0 if found else 1


if __name__ == "__main__":
    raise SystemExit(main())
