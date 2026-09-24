from pathlib import Path
import random
import shutil


# ---------------------------------------------------------
# PROJECT PATHS
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent

SOURCE_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "raw"
)

OUTPUT_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "split"
)


# ---------------------------------------------------------
# DATASET SETTINGS
# ---------------------------------------------------------

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


TRAIN_RATIO = 0.70
VALIDATION_RATIO = 0.15
TEST_RATIO = 0.15

RANDOM_SEED = 42


# ---------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------

def get_images(class_directory: Path):

    images = []

    for file_path in class_directory.iterdir():

        if (
            file_path.is_file()
            and file_path.suffix.lower() in VALID_EXTENSIONS
        ):
            images.append(file_path)

    return images


def create_output_directories():

    for split_name in [
        "train",
        "validation",
        "test",
    ]:

        for class_name in CLASS_NAMES:

            directory = (
                OUTPUT_DIR
                / split_name
                / class_name
            )

            directory.mkdir(
                parents=True,
                exist_ok=True
            )


def output_contains_files():

    if not OUTPUT_DIR.exists():
        return False

    return any(
        path.is_file()
        for path in OUTPUT_DIR.rglob("*")
    )


def copy_images(
    images,
    destination
):

    for image_path in images:

        destination_path = (
            destination
            / image_path.name
        )

        shutil.copy2(
            image_path,
            destination_path
        )


# ---------------------------------------------------------
# SPLIT ONE CLASS
# ---------------------------------------------------------

def split_class(class_name: str):

    class_directory = (
        SOURCE_DIR
        / class_name
    )


    if not class_directory.exists():

        raise FileNotFoundError(
            f"Missing class folder: {class_directory}"
        )


    images = get_images(
        class_directory
    )


    if not images:

        raise ValueError(
            f"No images found for class: {class_name}"
        )


    random.shuffle(images)


    total_images = len(images)


    train_count = int(
        total_images * TRAIN_RATIO
    )

    validation_count = int(
        total_images * VALIDATION_RATIO
    )


    train_images = images[
        :train_count
    ]


    validation_images = images[
        train_count:
        train_count + validation_count
    ]


    test_images = images[
        train_count + validation_count:
    ]


    copy_images(
        train_images,
        OUTPUT_DIR / "train" / class_name
    )


    copy_images(
        validation_images,
        OUTPUT_DIR / "validation" / class_name
    )


    copy_images(
        test_images,
        OUTPUT_DIR / "test" / class_name
    )


    print(
        f"\n{class_name.upper()}"
    )

    print(
        f"Total:      {total_images}"
    )

    print(
        f"Train:      {len(train_images)}"
    )

    print(
        f"Validation: {len(validation_images)}"
    )

    print(
        f"Test:       {len(test_images)}"
    )


# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():

    print(
        "gUSo Dataset Splitter"
    )

    print(
        f"Source: {SOURCE_DIR}"
    )

    print(
        f"Output: {OUTPUT_DIR}"
    )


    if output_contains_files():

        print(
            "\nERROR:"
            "\nThe split dataset directory already contains files."
        )

        print(
            "Delete dataset/quality/split "
            "before running this script again."
        )

        return


    random.seed(
        RANDOM_SEED
    )


    create_output_directories()


    for class_name in CLASS_NAMES:

        split_class(
            class_name
        )


    print(
        "\nDataset splitting completed successfully."
    )


if __name__ == "__main__":
    main()