from pathlib import Path
from collections import Counter

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parent.parent

DATASET_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "raw"
)

CLASS_NAMES = [
    "fresh",
    "regular",
    "poor",
]

VALID_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
}


def inspect_class(class_name: str):

    class_dir = DATASET_DIR / class_name

    if not class_dir.exists():
        print(f"\n[ERROR] Missing folder: {class_dir}")
        return 0

    files = [
        path
        for path in class_dir.iterdir()
        if path.is_file()
    ]

    valid_images = 0
    corrupted_images = []
    extensions = Counter()
    dimensions = Counter()

    for file_path in files:

        extension = file_path.suffix.lower()

        if extension not in VALID_EXTENSIONS:
            continue

        extensions[extension] += 1

        try:

            with Image.open(file_path) as image:

                image.verify()

            with Image.open(file_path) as image:

                dimensions[image.size] += 1

            valid_images += 1

        except Exception as error:

            corrupted_images.append(
                (
                    file_path.name,
                    str(error)
                )
            )

    print("\n" + "=" * 50)

    print(
        f"CLASS: {class_name.upper()}"
    )

    print(
        f"Valid images: {valid_images}"
    )

    print(
        f"Formats: {dict(extensions)}"
    )

    if dimensions:

        print(
            "Most common dimensions:"
        )

        for dimension, count in dimensions.most_common(5):

            print(
                f"  {dimension[0]} x {dimension[1]} : {count}"
            )

    if corrupted_images:

        print(
            f"Corrupted images: {len(corrupted_images)}"
        )

        for filename, error in corrupted_images:

            print(
                f"  {filename}: {error}"
            )

    else:

        print(
            "Corrupted images: 0"
        )

    return valid_images


def main():

    print(
        "gUSo Quality Dataset Check"
    )

    print(
        f"Dataset directory: {DATASET_DIR}"
    )

    totals = {}

    for class_name in CLASS_NAMES:

        totals[class_name] = inspect_class(
            class_name
        )

    print("\n" + "=" * 50)

    print(
        "DATASET SUMMARY"
    )

    total_images = sum(
        totals.values()
    )

    for class_name, count in totals.items():

        print(
            f"{class_name.capitalize()}: {count}"
        )

    print(
        f"Total images: {total_images}"
    )

    if total_images == 0:

        print(
            "\nNo images found yet."
        )

        return

    non_zero_counts = [
        count
        for count in totals.values()
        if count > 0
    ]

    if len(non_zero_counts) == len(CLASS_NAMES):

        largest = max(non_zero_counts)
        smallest = min(non_zero_counts)

        if smallest > 0:

            ratio = largest / smallest

            print(
                f"Class imbalance ratio: {ratio:.2f}:1"
            )

            if ratio > 2:

                print(
                    "WARNING: Dataset may be significantly imbalanced."
                )

            else:

                print(
                    "Class distribution looks reasonably balanced."
                )


if __name__ == "__main__":
    main()