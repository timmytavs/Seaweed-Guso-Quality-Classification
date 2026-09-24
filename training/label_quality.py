from pathlib import Path
import shutil
import random
import tkinter as tk

from PIL import Image, ImageTk


# =========================================================
# PATHS
# =========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

SOURCE_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "species"
    / "train"
)

QUALITY_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "raw"
)


FRESH_DIR = QUALITY_DIR / "fresh"
REGULAR_DIR = QUALITY_DIR / "regular"
POOR_DIR = QUALITY_DIR / "poor"


for folder in [
    FRESH_DIR,
    REGULAR_DIR,
    POOR_DIR
]:
    folder.mkdir(
        parents=True,
        exist_ok=True
    )


# =========================================================
# IMAGE SETTINGS
# =========================================================

VALID_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png"
}


DISPLAY_WIDTH = 700
DISPLAY_HEIGHT = 550


# =========================================================
# LOAD IMAGE FILES
# =========================================================

image_files = [
    file_path
    for file_path in SOURCE_DIR.rglob("*")
    if (
        file_path.is_file()
        and file_path.suffix.lower()
        in VALID_EXTENSIONS
    )
]


random.shuffle(image_files)


if not image_files:

    raise RuntimeError(
        f"No images found in:\n{SOURCE_DIR}"
    )


# =========================================================
# APPLICATION
# =========================================================

class QualityLabeler:

    def __init__(
        self,
        root
    ):

        self.root = root

        self.root.title(
            "gUSo Quality Dataset Labeler"
        )

        self.current_index = 0

        self.current_photo = None


        self.title_label = tk.Label(
            root,
            text="gUSo Quality Labeling",
            font=("Arial", 20, "bold")
        )

        self.title_label.pack(
            pady=10
        )


        self.image_label = tk.Label(
            root
        )

        self.image_label.pack(
            padx=20,
            pady=10
        )


        self.file_label = tk.Label(
            root,
            text="",
            font=("Arial", 11)
        )

        self.file_label.pack(
            pady=5
        )


        self.instructions = tk.Label(
            root,
            text=(
                "F = Fresh    "
                "R = Regular    "
                "P = Poor    "
                "S = Skip    "
                "Q = Quit"
            ),
            font=("Arial", 13, "bold")
        )

        self.instructions.pack(
            pady=10
        )


        self.counter_label = tk.Label(
            root,
            text=""
        )

        self.counter_label.pack(
            pady=5
        )


        self.root.bind(
            "<Key>",
            self.handle_key
        )


        self.show_image()


    def show_image(self):

        if self.current_index >= len(image_files):

            self.image_label.config(
                image=""
            )

            self.file_label.config(
                text="All images reviewed."
            )

            return


        image_path = image_files[
            self.current_index
        ]


        image = Image.open(
            image_path
        ).convert(
            "RGB"
        )


        image.thumbnail(
            (
                DISPLAY_WIDTH,
                DISPLAY_HEIGHT
            )
        )


        self.current_photo = (
            ImageTk.PhotoImage(
                image
            )
        )


        self.image_label.config(
            image=self.current_photo
        )


        self.file_label.config(
            text=str(
                image_path.relative_to(
                    PROJECT_ROOT
                )
            )
        )


        self.counter_label.config(
            text=(
                f"Image "
                f"{self.current_index + 1}"
                f" / "
                f"{len(image_files)}"
            )
        )


    def save_label(
        self,
        destination
    ):

        source = image_files[
            self.current_index
        ]


        class_name = source.parent.name


        destination_name = (
            f"{class_name}_"
            f"{source.name}"
        )


        destination_path = (
            destination
            / destination_name
        )


        shutil.copy2(
            source,
            destination_path
        )


        self.current_index += 1

        self.show_image()


    def skip_image(self):

        self.current_index += 1

        self.show_image()


    def handle_key(
        self,
        event
    ):

        key = event.keysym.lower()


        if key == "f":

            self.save_label(
                FRESH_DIR
            )


        elif key == "r":

            self.save_label(
                REGULAR_DIR
            )


        elif key == "p":

            self.save_label(
                POOR_DIR
            )


        elif key == "s":

            self.skip_image()


        elif key == "q":

            self.root.destroy()


# =========================================================
# START
# =========================================================

root = tk.Tk()

app = QualityLabeler(
    root
)

root.mainloop()