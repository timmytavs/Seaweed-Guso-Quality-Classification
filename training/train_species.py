from pathlib import Path
import csv
import json
import time

import torch
import torch.nn as nn

from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from torchvision.models import (
    mobilenet_v3_small,
    MobileNet_V3_Small_Weights,
)

from tqdm import tqdm


# =========================================================
# PROJECT PATHS
# =========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

TRAIN_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "species"
    / "train"
)

VALIDATION_DIR = (
    PROJECT_ROOT
    / "dataset"
    / "species"
    / "validation"
)

CHECKPOINT_DIR = (
    PROJECT_ROOT
    / "training"
    / "checkpoints"
)

CHECKPOINT_DIR.mkdir(
    parents=True,
    exist_ok=True
)

BEST_MODEL_PATH = (
    CHECKPOINT_DIR
    / "species_mobilenetv3_best.pth"
)

HISTORY_PATH = (
    CHECKPOINT_DIR
    / "species_training_history.csv"
)

CLASS_MAPPING_PATH = (
    CHECKPOINT_DIR
    / "species_class_mapping.json"
)


# =========================================================
# TRAINING SETTINGS
# =========================================================

IMAGE_SIZE = 224

BATCH_SIZE = 32

# Keep this at 1 first.
# Change to 10 or more after the test succeeds.
EPOCHS = 1

LEARNING_RATE = 0.001

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

    print(
        "Training device: CPU"
    )


# =========================================================
# IMAGE TRANSFORMS
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
            brightness=0.1,
            contrast=0.1,
            saturation=0.1
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
# DATASETS
# =========================================================

train_dataset = datasets.ImageFolder(
    root=TRAIN_DIR,
    transform=train_transform
)


validation_dataset = datasets.ImageFolder(
    root=VALIDATION_DIR,
    transform=validation_transform
)


# Make sure both datasets use the same class mapping.
if (
    train_dataset.class_to_idx
    != validation_dataset.class_to_idx
):

    raise ValueError(
        "Training and validation class mappings do not match."
    )


print(
    "\nClasses detected:"
)

for class_name, index in train_dataset.class_to_idx.items():

    print(
        f"{index}: {class_name}"
    )


print(
    f"\nTraining images: "
    f"{len(train_dataset)}"
)

print(
    f"Validation images: "
    f"{len(validation_dataset)}"
)


# =========================================================
# SAVE CLASS MAPPING
# =========================================================

with open(
    CLASS_MAPPING_PATH,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        {
            "class_to_idx":
                train_dataset.class_to_idx,

            "classes":
                train_dataset.classes
        },
        file,
        indent=4
    )


print(
    f"\nClass mapping saved to:"
    f"\n{CLASS_MAPPING_PATH}"
)


# =========================================================
# DATA LOADERS
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
# MODEL
# =========================================================

weights = (
    MobileNet_V3_Small_Weights.DEFAULT
)


model = mobilenet_v3_small(
    weights=weights
)


num_classes = len(
    train_dataset.classes
)


input_features = (
    model.classifier[3].in_features
)


model.classifier[3] = nn.Linear(
    input_features,
    num_classes
)


model = model.to(
    DEVICE
)


# =========================================================
# LOSS
# =========================================================

criterion = nn.CrossEntropyLoss()


# =========================================================
# OPTIMIZER
# =========================================================

optimizer = torch.optim.Adam(
    model.parameters(),
    lr=LEARNING_RATE
)


# =========================================================
# LEARNING-RATE SCHEDULER
# =========================================================

scheduler = (
    torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer,
        mode="min",
        factor=0.5,
        patience=1
    )
)


# =========================================================
# TRAIN ONE EPOCH
# =========================================================

def train_one_epoch(
    epoch_number: int
):

    model.train()

    running_loss = 0.0
    correct = 0
    total = 0


    progress_bar = tqdm(
        train_loader,
        desc=(
            f"Epoch {epoch_number}/{EPOCHS} "
            f"[Training]"
        ),
        unit="batch"
    )


    for images, labels in progress_bar:

        images = images.to(
            DEVICE,
            non_blocking=True
        )

        labels = labels.to(
            DEVICE,
            non_blocking=True
        )


        optimizer.zero_grad()


        outputs = model(
            images
        )


        loss = criterion(
            outputs,
            labels
        )


        loss.backward()


        optimizer.step()


        batch_size = labels.size(0)


        running_loss += (
            loss.item()
            * batch_size
        )


        _, predictions = torch.max(
            outputs,
            dim=1
        )


        total += batch_size


        correct += (
            predictions == labels
        ).sum().item()


        current_loss = (
            running_loss
            / total
        )


        current_accuracy = (
            correct
            / total
        )


        progress_bar.set_postfix(
            loss=f"{current_loss:.4f}",
            acc=(
                f"{current_accuracy * 100:.2f}%"
            )
        )


    epoch_loss = (
        running_loss
        / total
    )


    epoch_accuracy = (
        correct
        / total
    )


    return (
        epoch_loss,
        epoch_accuracy
    )


# =========================================================
# VALIDATION
# =========================================================

def validate(
    epoch_number: int
):

    model.eval()

    running_loss = 0.0
    correct = 0
    total = 0


    progress_bar = tqdm(
        validation_loader,
        desc=(
            f"Epoch {epoch_number}/{EPOCHS} "
            f"[Validation]"
        ),
        unit="batch"
    )


    with torch.no_grad():

        for images, labels in progress_bar:

            images = images.to(
                DEVICE,
                non_blocking=True
            )

            labels = labels.to(
                DEVICE,
                non_blocking=True
            )


            outputs = model(
                images
            )


            loss = criterion(
                outputs,
                labels
            )


            batch_size = labels.size(0)


            running_loss += (
                loss.item()
                * batch_size
            )


            _, predictions = torch.max(
                outputs,
                dim=1
            )


            total += batch_size


            correct += (
                predictions == labels
            ).sum().item()


            current_loss = (
                running_loss
                / total
            )


            current_accuracy = (
                correct
                / total
            )


            progress_bar.set_postfix(
                loss=f"{current_loss:.4f}",
                acc=(
                    f"{current_accuracy * 100:.2f}%"
                )
            )


    validation_loss = (
        running_loss
        / total
    )


    validation_accuracy = (
        correct
        / total
    )


    return (
        validation_loss,
        validation_accuracy
    )


# =========================================================
# SAVE CHECKPOINT
# =========================================================

def save_checkpoint(
    epoch,
    validation_accuracy,
    validation_loss
):

    checkpoint = {

        "model_name":
            "mobilenet_v3_small",

        "model_state_dict":
            model.state_dict(),

        "class_to_idx":
            train_dataset.class_to_idx,

        "classes":
            train_dataset.classes,

        "num_classes":
            num_classes,

        "image_size":
            IMAGE_SIZE,

        "epoch":
            epoch,

        "validation_accuracy":
            validation_accuracy,

        "validation_loss":
            validation_loss
    }


    torch.save(
        checkpoint,
        BEST_MODEL_PATH
    )


# =========================================================
# SAVE TRAINING HISTORY
# =========================================================

def initialize_history_file():

    with open(
        HISTORY_PATH,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.writer(
            file
        )

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


def append_history(
    epoch,
    train_loss,
    train_accuracy,
    validation_loss,
    validation_accuracy,
    learning_rate,
    elapsed_time
):

    with open(
        HISTORY_PATH,
        "a",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.writer(
            file
        )

        writer.writerow(
            [
                epoch,
                train_loss,
                train_accuracy,
                validation_loss,
                validation_accuracy,
                learning_rate,
                elapsed_time
            ]
        )


# =========================================================
# TRAINING LOOP
# =========================================================

def main():

    best_validation_accuracy = 0.0

    epochs_without_improvement = 0


    initialize_history_file()


    print(
        "\nStarting automated training..."
    )


    for epoch in range(
        1,
        EPOCHS + 1
    ):

        start_time = time.time()


        train_loss, train_accuracy = (
            train_one_epoch(
                epoch
            )
        )


        validation_loss, validation_accuracy = (
            validate(
                epoch
            )
        )


        scheduler.step(
            validation_loss
        )


        elapsed_time = (
            time.time()
            - start_time
        )


        current_lr = (
            optimizer.param_groups[0]["lr"]
        )


        print(
            "\n"
            + "=" * 55
        )

        print(
            f"Epoch {epoch}/{EPOCHS} completed"
        )

        print(
            f"Train Loss: "
            f"{train_loss:.4f}"
        )

        print(
            f"Train Accuracy: "
            f"{train_accuracy * 100:.2f}%"
        )

        print(
            f"Validation Loss: "
            f"{validation_loss:.4f}"
        )

        print(
            f"Validation Accuracy: "
            f"{validation_accuracy * 100:.2f}%"
        )

        print(
            f"Learning Rate: "
            f"{current_lr}"
        )

        print(
            f"Epoch Time: "
            f"{elapsed_time / 60:.2f} minutes"
        )

        print(
            "=" * 55
        )


        append_history(
            epoch,
            train_loss,
            train_accuracy,
            validation_loss,
            validation_accuracy,
            current_lr,
            elapsed_time
        )


        if (
            validation_accuracy
            > best_validation_accuracy
        ):

            best_validation_accuracy = (
                validation_accuracy
            )

            epochs_without_improvement = 0


            save_checkpoint(
                epoch,
                validation_accuracy,
                validation_loss
            )


            print(
                "\nBest model updated and saved."
            )

        else:

            epochs_without_improvement += 1


            print(
                "\nNo improvement."
            )

            print(
                "Early stopping counter: "
                f"{epochs_without_improvement}/"
                f"{EARLY_STOPPING_PATIENCE}"
            )


        if (
            epochs_without_improvement
            >= EARLY_STOPPING_PATIENCE
        ):

            print(
                "\nEarly stopping activated."
            )

            break


    print(
        "\nTraining finished."
    )


    print(
        "Best validation accuracy: "
        f"{best_validation_accuracy * 100:.2f}%"
    )


    print(
        "\nBest model:"
    )

    print(
        BEST_MODEL_PATH
    )


    print(
        "\nTraining history:"
    )

    print(
        HISTORY_PATH
    )


if __name__ == "__main__":
    main()