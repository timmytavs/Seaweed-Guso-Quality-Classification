from pathlib import Path
import csv
import json
import time

import torch
import torch.nn as nn

from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from torchvision.models import mobilenet_v3_small

from tqdm import tqdm


# =========================================================
# PATHS
# =========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

TRAIN_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "split"
    / "train"
)

VALIDATION_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "quality"
    / "split"
    / "validation"
)

CHECKPOINT_DIR = (
    PROJECT_ROOT
    / "training"
    / "checkpoints"
)

SPECIES_MODEL_PATH = (
    CHECKPOINT_DIR
    / "species_mobilenetv3_best.pth"
)

QUALITY_MODEL_PATH = (
    CHECKPOINT_DIR
    / "quality_mobilenetv3_best.pth"
)

QUALITY_MAPPING_PATH = (
    CHECKPOINT_DIR
    / "quality_class_mapping.json"
)

QUALITY_HISTORY_PATH = (
    CHECKPOINT_DIR
    / "quality_training_history.csv"
)


# =========================================================
# SETTINGS
# =========================================================

IMAGE_SIZE = 224
BATCH_SIZE = 32

EPOCHS = 10

LEARNING_RATE = 0.0001

NUM_WORKERS = 0

EARLY_STOPPING_PATIENCE = 3


# =========================================================
# DEVICE
# =========================================================

if torch.cuda.is_available():

    DEVICE = torch.device("cuda")

    print(
        f"Training device: CUDA - "
        f"{torch.cuda.get_device_name(0)}"
    )

else:

    DEVICE = torch.device("cpu")

    print("Training device: CPU")


# =========================================================
# TRANSFORMS
# =========================================================

train_transform = transforms.Compose(
    [
        transforms.Resize(
            (IMAGE_SIZE, IMAGE_SIZE)
        ),

        transforms.RandomHorizontalFlip(),

        transforms.RandomRotation(
            degrees=10
        ),

        transforms.ColorJitter(
            brightness=0.08,
            contrast=0.08,
            saturation=0.08
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
        transforms.Resize(
            (IMAGE_SIZE, IMAGE_SIZE)
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


# =========================================================
# DATASET
# =========================================================

train_dataset = datasets.ImageFolder(
    TRAIN_DIR,
    transform=train_transform
)

validation_dataset = datasets.ImageFolder(
    VALIDATION_DIR,
    transform=validation_transform
)


EXPECTED_CLASSES = {
    "fresh",
    "regular",
    "poor"
}


if set(train_dataset.classes) != EXPECTED_CLASSES:

    raise ValueError(
        "Quality dataset must contain exactly: "
        "fresh, regular, poor"
    )


if (
    train_dataset.class_to_idx
    != validation_dataset.class_to_idx
):

    raise ValueError(
        "Training and validation class mappings differ."
    )


print("\nQuality classes:")

for class_name, index in train_dataset.class_to_idx.items():

    print(
        f"{index}: {class_name}"
    )


print(
    f"\nTraining images: {len(train_dataset)}"
)

print(
    f"Validation images: {len(validation_dataset)}"
)


# =========================================================
# SAVE CLASS MAPPING
# =========================================================

with open(
    QUALITY_MAPPING_PATH,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        {
            "classes":
                train_dataset.classes,

            "class_to_idx":
                train_dataset.class_to_idx
        },
        file,
        indent=4
    )


# =========================================================
# LOADERS
# =========================================================

train_loader = DataLoader(
    train_dataset,
    batch_size=BATCH_SIZE,
    shuffle=True,
    num_workers=NUM_WORKERS,
    pin_memory=torch.cuda.is_available()
)


validation_loader = DataLoader(
    validation_dataset,
    batch_size=BATCH_SIZE,
    shuffle=False,
    num_workers=NUM_WORKERS,
    pin_memory=torch.cuda.is_available()
)


# =========================================================
# LOAD SPECIES-PRETRAINED MODEL
# =========================================================

if not SPECIES_MODEL_PATH.exists():

    raise FileNotFoundError(
        f"Species checkpoint not found:\n"
        f"{SPECIES_MODEL_PATH}"
    )


species_checkpoint = torch.load(
    SPECIES_MODEL_PATH,
    map_location="cpu"
)


species_num_classes = species_checkpoint[
    "num_classes"
]


model = mobilenet_v3_small(
    weights=None
)


input_features = (
    model.classifier[3].in_features
)


# Recreate the 7-class head first so the
# species checkpoint can be loaded correctly.

model.classifier[3] = nn.Linear(
    input_features,
    species_num_classes
)


model.load_state_dict(
    species_checkpoint[
        "model_state_dict"
    ]
)


print(
    "\nSpecies-pretrained checkpoint loaded."
)


# =========================================================
# REPLACE WITH QUALITY CLASSIFIER
# =========================================================

QUALITY_CLASS_COUNT = 3


model.classifier[3] = nn.Linear(
    input_features,
    QUALITY_CLASS_COUNT
)


model = model.to(
    DEVICE
)


# =========================================================
# LOSS + OPTIMIZER
# =========================================================

criterion = nn.CrossEntropyLoss()


optimizer = torch.optim.Adam(
    model.parameters(),
    lr=LEARNING_RATE
)


scheduler = (
    torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer,
        mode="min",
        factor=0.5,
        patience=1
    )
)


# =========================================================
# TRAIN
# =========================================================

def train_one_epoch(epoch):

    model.train()

    total_loss = 0.0
    correct = 0
    total = 0


    progress = tqdm(
        train_loader,
        desc=f"Epoch {epoch}/{EPOCHS} [Training]",
        unit="batch"
    )


    for images, labels in progress:

        images = images.to(
            DEVICE,
            non_blocking=True
        )

        labels = labels.to(
            DEVICE,
            non_blocking=True
        )


        optimizer.zero_grad()


        output = model(images)


        loss = criterion(
            output,
            labels
        )


        loss.backward()

        optimizer.step()


        batch_size = labels.size(0)

        total_loss += (
            loss.item()
            * batch_size
        )


        predictions = output.argmax(
            dim=1
        )


        correct += (
            predictions == labels
        ).sum().item()


        total += batch_size


        progress.set_postfix(
            loss=(
                f"{total_loss / total:.4f}"
            ),
            acc=(
                f"{correct / total * 100:.2f}%"
            )
        )


    return (
        total_loss / total,
        correct / total
    )


# =========================================================
# VALIDATE
# =========================================================

def validate(epoch):

    model.eval()

    total_loss = 0.0
    correct = 0
    total = 0


    progress = tqdm(
        validation_loader,
        desc=f"Epoch {epoch}/{EPOCHS} [Validation]",
        unit="batch"
    )


    with torch.no_grad():

        for images, labels in progress:

            images = images.to(
                DEVICE,
                non_blocking=True
            )

            labels = labels.to(
                DEVICE,
                non_blocking=True
            )


            output = model(images)


            loss = criterion(
                output,
                labels
            )


            batch_size = labels.size(0)


            total_loss += (
                loss.item()
                * batch_size
            )


            predictions = output.argmax(
                dim=1
            )


            correct += (
                predictions == labels
            ).sum().item()


            total += batch_size


            progress.set_postfix(
                loss=(
                    f"{total_loss / total:.4f}"
                ),
                acc=(
                    f"{correct / total * 100:.2f}%"
                )
            )


    return (
        total_loss / total,
        correct / total
    )


# =========================================================
# SAVE BEST MODEL
# =========================================================

def save_model(
    epoch,
    validation_loss,
    validation_accuracy
):

    torch.save(
        {
            "model_name":
                "mobilenet_v3_small",

            "model_state_dict":
                model.state_dict(),

            "classes":
                train_dataset.classes,

            "class_to_idx":
                train_dataset.class_to_idx,

            "num_classes":
                QUALITY_CLASS_COUNT,

            "image_size":
                IMAGE_SIZE,

            "epoch":
                epoch,

            "validation_loss":
                validation_loss,

            "validation_accuracy":
                validation_accuracy
        },
        QUALITY_MODEL_PATH
    )


# =========================================================
# HISTORY
# =========================================================

def create_history():

    with open(
        QUALITY_HISTORY_PATH,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.writer(file)

        writer.writerow(
            [
                "epoch",
                "train_loss",
                "train_accuracy",
                "validation_loss",
                "validation_accuracy",
                "learning_rate",
                "seconds"
            ]
        )


def save_history(
    epoch,
    train_loss,
    train_accuracy,
    validation_loss,
    validation_accuracy,
    learning_rate,
    seconds
):

    with open(
        QUALITY_HISTORY_PATH,
        "a",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.writer(file)

        writer.writerow(
            [
                epoch,
                train_loss,
                train_accuracy,
                validation_loss,
                validation_accuracy,
                learning_rate,
                seconds
            ]
        )


# =========================================================
# MAIN TRAINING LOOP
# =========================================================

def main():

    best_accuracy = 0.0

    no_improvement = 0


    create_history()


    print(
        "\nStarting Fresh / Regular / Poor training..."
    )


    for epoch in range(
        1,
        EPOCHS + 1
    ):

        start = time.time()


        train_loss, train_accuracy = (
            train_one_epoch(epoch)
        )


        val_loss, val_accuracy = (
            validate(epoch)
        )


        scheduler.step(
            val_loss
        )


        elapsed = (
            time.time()
            - start
        )


        learning_rate = (
            optimizer.param_groups[0]["lr"]
        )


        print(
            "\n"
            + "=" * 55
        )

        print(
            f"Epoch {epoch}/{EPOCHS}"
        )

        print(
            f"Train Loss: {train_loss:.4f}"
        )

        print(
            "Train Accuracy: "
            f"{train_accuracy * 100:.2f}%"
        )

        print(
            f"Validation Loss: {val_loss:.4f}"
        )

        print(
            "Validation Accuracy: "
            f"{val_accuracy * 100:.2f}%"
        )

        print(
            f"Epoch Time: {elapsed / 60:.2f} minutes"
        )

        print(
            "=" * 55
        )


        save_history(
            epoch,
            train_loss,
            train_accuracy,
            val_loss,
            val_accuracy,
            learning_rate,
            elapsed
        )


        if val_accuracy > best_accuracy:

            best_accuracy = val_accuracy

            no_improvement = 0


            save_model(
                epoch,
                val_loss,
                val_accuracy
            )


            print(
                "Best quality model saved."
            )

        else:

            no_improvement += 1


            print(
                "No improvement: "
                f"{no_improvement}/"
                f"{EARLY_STOPPING_PATIENCE}"
            )


        if (
            no_improvement
            >= EARLY_STOPPING_PATIENCE
        ):

            print(
                "\nEarly stopping activated."
            )

            break


    print(
        "\nQuality training complete."
    )

    print(
        "Best validation accuracy: "
        f"{best_accuracy * 100:.2f}%"
    )

    print(
        f"\nModel:\n{QUALITY_MODEL_PATH}"
    )


if __name__ == "__main__":
    main()