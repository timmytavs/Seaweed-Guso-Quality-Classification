from pathlib import Path

from PIL import Image

import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms


PROJECT_ROOT = Path(__file__).resolve().parents[1]

DATASET_ROOT = (
    PROJECT_ROOT
    / "dataset"
    / "raw"
    / "8_DATASET"
)


IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".bmp",
    ".webp",
}


# ---------------------------------------------------------
# MobileNetV3 image transformations
# ---------------------------------------------------------

train_transform = transforms.Compose(
    [
        transforms.Resize((256, 256)),

        transforms.RandomResizedCrop(
            size=224,
            scale=(0.8, 1.0)
        ),

        transforms.RandomHorizontalFlip(
            p=0.5
        ),

        transforms.RandomRotation(
            degrees=15
        ),

        transforms.ColorJitter(
            brightness=0.15,
            contrast=0.15,
            saturation=0.15
        ),

        transforms.ToTensor(),

        transforms.Normalize(
            mean=[
                0.485,
                0.456,
                0.406
            ],
            std=[
                0.229,
                0.224,
                0.225
            ]
        )
    ]
)


validation_transform = transforms.Compose(
    [
        transforms.Resize((224, 224)),

        transforms.ToTensor(),

        transforms.Normalize(
            mean=[
                0.485,
                0.456,
                0.406
            ],
            std=[
                0.229,
                0.224,
                0.225
            ]
        )
    ]
)


# ---------------------------------------------------------
# Custom seaweed dataset
# ---------------------------------------------------------

class SeaweedDataset(Dataset):

    def __init__(
        self,
        root_dir: Path,
        split: str,
        transform=None
    ):

        self.root_dir = Path(root_dir)

        self.split = split

        self.transform = transform


        self.class_names = sorted(
            [
                folder.name
                for folder in self.root_dir.iterdir()
                if folder.is_dir()
            ]
        )


        self.class_to_idx = {
            class_name: index
            for index, class_name
            in enumerate(self.class_names)
        }


        self.samples = []


        for class_name in self.class_names:

            class_folder = (
                self.root_dir
                / class_name
                / split
            )


            if not class_folder.exists():
                continue


            for image_path in class_folder.rglob("*"):

                if (
                    image_path.is_file()
                    and
                    image_path.suffix.lower()
                    in IMAGE_EXTENSIONS
                ):

                    label = self.class_to_idx[
                        class_name
                    ]

                    self.samples.append(
                        (
                            image_path,
                            label
                        )
                    )


    def __len__(self):

        return len(self.samples)


    def __getitem__(
        self,
        index
    ):

        image_path, label = (
            self.samples[index]
        )


        image = Image.open(
            image_path
        ).convert("RGB")


        if self.transform:

            image = self.transform(
                image
            )


        return image, label


# ---------------------------------------------------------
# Build DataLoaders
# ---------------------------------------------------------

def create_dataloaders(
    batch_size: int = 32,
    num_workers: int = 0
):

    train_dataset = SeaweedDataset(
        root_dir=DATASET_ROOT,
        split="train",
        transform=train_transform
    )


    validation_dataset = SeaweedDataset(
        root_dir=DATASET_ROOT,
        split="validation",
        transform=validation_transform
    )


    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers
    )


    validation_loader = DataLoader(
        validation_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers
    )


    return (
        train_loader,
        validation_loader,
        train_dataset
    )


# ---------------------------------------------------------
# Test this file directly
# ---------------------------------------------------------

if __name__ == "__main__":

    train_loader, validation_loader, dataset = (
        create_dataloaders()
    )


    print(
        f"Classes: {dataset.class_names}"
    )

    print(
        f"Class mapping: {dataset.class_to_idx}"
    )

    print(
        f"Training images: "
        f"{len(train_loader.dataset)}"
    )

    print(
        f"Validation images: "
        f"{len(validation_loader.dataset)}"
    )


    images, labels = next(
        iter(train_loader)
    )


    print(
        f"Batch image shape: "
        f"{images.shape}"
    )

    print(
        f"Batch label shape: "
        f"{labels.shape}"
    )