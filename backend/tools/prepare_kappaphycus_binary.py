"""Prepare leak-checked binary manifests from the existing seven-species dataset.

Run from backend/:
    python tools/prepare_kappaphycus_binary.py

Does not copy, alter, or move images; does not retrain or overwrite checkpoints.
"""

import argparse
import csv
import hashlib
import json
import random
from collections import Counter
from pathlib import Path

TARGET = "KAPPAPHYCUS"
OTHER = "OTHER_SEAWEED"
CLASS_TO_IDX = {OTHER: 0, TARGET: 1}
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def images_in(folder: Path) -> list[Path]:
    return sorted(
        (p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in EXTENSIONS),
        key=lambda p: str(p).casefold(),
    )


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_split(root: Path) -> dict[str, list[Path]]:
    if not root.is_dir():
        raise FileNotFoundError(f"Missing dataset split: {root}")
    result = {folder.name: images_in(folder) for folder in sorted(root.iterdir()) if folder.is_dir()}
    if TARGET not in result or not result[TARGET]:
        raise ValueError(f"No {TARGET} images found in {root}")
    if not any(result[name] for name in result if name != TARGET):
        raise ValueError(f"No negative seaweed images found in {root}")
    return result


def make_rows(split: str, species: str, paths: list[Path]) -> list[dict]:
    label = TARGET if species == TARGET else OTHER
    return [
        {
            "image_path": str(path.resolve()),
            "label": label,
            "class_index": CLASS_TO_IDX[label],
            "source_species": species,
            "split": split,
        }
        for path in paths
    ]


def check_exact_leakage(train_rows: list[dict], val_rows: list[dict]) -> int:
    """Reject identical bytes across splits or contradictory training labels."""
    seen_train: dict[str, dict] = {}
    repeated_train = 0
    print(f"Hashing {len(train_rows)} training images for exact duplicates...")
    for index, row in enumerate(train_rows, start=1):
        digest = file_hash(Path(row["image_path"]))
        existing = seen_train.get(digest)
        if existing:
            if existing["class_index"] != row["class_index"]:
                raise ValueError(
                    "Same image content assigned two opposing training labels:\n"
                    f"  {existing['image_path']}\n  {row['image_path']}"
                )
            repeated_train += 1
        else:
            seen_train[digest] = row
        if index % 5000 == 0:
            print(f"  Checked {index}/{len(train_rows)} training images")
    print(f"Checking {len(val_rows)} validation images against training images...")
    for row in val_rows:
        digest = file_hash(Path(row["image_path"]))
        if digest in seen_train:
            raise ValueError(
                "Exact train/validation image overlap detected:\n"
                f"  train: {seen_train[digest]['image_path']}\n"
                f"  validation: {row['image_path']}\n"
                "Review the dataset split before training."
            )
    return repeated_train


def write_csv(path: Path, rows: list[dict]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["image_path", "label", "class_index", "source_species", "split"],
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    default_project = Path(__file__).resolve().parents[2]
    parser.add_argument(
        "--dataset", type=Path, default=default_project / "dataset" / "species",
        help="Path to species/ containing train/ and validation/",
    )
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).resolve().parents[1] / "reports",
        help="Folder to write CSV manifests and summary",
    )
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    root = args.dataset.expanduser().resolve()
    train = collect_split(root / "train")
    validation = collect_split(root / "validation")
    negatives = sorted(name for name in train if name != TARGET and train[name])
    if set(train) != set(validation):
        raise ValueError("Train and validation species folder sets differ; review the splits.")

    # Equal total positive and negative examples, with negatives spread across
    # each of the other six species to avoid overrepresenting one species.
    positives = train[TARGET]
    requested_negatives = len(positives)
    base, remainder = divmod(requested_negatives, len(negatives))
    rng = random.Random(args.seed)
    selected: dict[str, list[Path]] = {}
    for index, name in enumerate(negatives):
        take = base + (1 if index < remainder else 0)
        if len(train[name]) < take:
            raise ValueError(
                f"Only {len(train[name])} training images available for {name}; "
                f"need {take} to keep the binary dataset balanced."
            )
        selected[name] = rng.sample(train[name], take)

    train_rows = make_rows("train", TARGET, positives)
    for name in negatives:
        train_rows.extend(make_rows("train", name, selected[name]))
    rng.shuffle(train_rows)

    # Keep ALL independent validation images, even though this results in
    # an imbalanced 50:300 KAPPAPHYCUS:OTHER_SEAWEED evaluation split.
    val_rows: list[dict] = []
    for name in sorted(validation):
        val_rows.extend(make_rows("validation", name, validation[name]))

    print(f"Dataset: {root}")
    print("Class indices:", CLASS_TO_IDX)
    print("Selected training source counts:", dict(Counter(row["source_species"] for row in train_rows)))
    print("Validation source counts:", dict(Counter(row["source_species"] for row in val_rows)))
    print("Checking exact train/validation overlap (may take a few minutes)...")
    repeated_train = check_exact_leakage(train_rows, val_rows)
    print("Exact train/validation overlap: NONE")
    print(f"Repeated identical images within selected train split: {repeated_train}")

    output = args.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    write_csv(output / "kappaphycus_binary_train.csv", train_rows)
    write_csv(output / "kappaphycus_binary_validation.csv", val_rows)
    summary = {
        "target_species": TARGET,
        "negative_label": OTHER,
        "class_to_idx": CLASS_TO_IDX,
        "random_seed": args.seed,
        "dataset_root": str(root),
        "train_counts": dict(Counter(row["label"] for row in train_rows)),
        "validation_counts": dict(Counter(row["label"] for row in val_rows)),
        "training_source_counts": dict(Counter(row["source_species"] for row in train_rows)),
        "validation_source_counts": dict(Counter(row["source_species"] for row in val_rows)),
        "exact_cross_split_overlap": 0,
        "identical_training_images": repeated_train,
        "note": (
            "An exact-hash check cannot detect augmented copies of the same "
            "original photo across train/validation. Review capture/source groups. "
            "Negatives currently cover other SEAWEEDS, not unrelated objects."
        ),
    }
    (output / "kappaphycus_binary_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )
    print(f"\nPrepared {len(train_rows)} training and {len(val_rows)} validation entries.")
    print(f"Manifests and summary written to: {output}")
    print("Original images and existing AI checkpoints were NOT changed.")


if __name__ == "__main__":
    main()