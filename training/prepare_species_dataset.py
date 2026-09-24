from pathlib import Path
import shutil


PROJECT_ROOT = Path(__file__).resolve().parent.parent

SOURCE_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "raw"
    / "8_DATASET"
)

OUTPUT_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "species"
)


CLASSES = [
    "CAULERPA LENTILIFERA",
    "CAULERPA SERTULARIOIDES",
    "KAPPAPHYCUS",
    "PADINA AUSTRALIS",
    "SARGASSUM MUTICUM",
    "TURBINARIA AUSTRALIS",
    "ULVA LACTUCA",
]


VALID_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
}


def copy_images(source, destination):

    destination.mkdir(
        parents=True,
        exist_ok=True
    )

    count = 0

    for image_path in source.iterdir():

        if (
            image_path.is_file()
            and image_path.suffix.lower()
            in VALID_EXTENSIONS
        ):

            shutil.copy2(
                image_path,
                destination / image_path.name
            )

            count += 1

    return count


def main():

    print("Preparing seaweed species dataset...\n")

    for class_name in CLASSES:

        class_source = (
            SOURCE_DIR
            / class_name
        )

        if not class_source.exists():

            print(
                f"[SKIP] Missing: {class_source}"
            )

            continue


        for split in [
            "train",
            "validation"
        ]:

            source = (
                class_source
                / split
            )

            destination = (
                OUTPUT_DIR
                / split
                / class_name
            )

            if not source.exists():

                print(
                    f"[SKIP] Missing: {source}"
                )

                continue


            count = copy_images(
                source,
                destination
            )

            print(
                f"{split:10} | "
                f"{class_name:30} | "
                f"{count} images"
            )


    print(
        "\nDataset preparation complete."
    )


if __name__ == "__main__":
    main()