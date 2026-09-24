from pathlib import Path

import torch
import torch.nn as nn
from torch.optim import Adam

from dataset_loader import create_dataloaders
from model import build_model


# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]

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
    / "best_mobilenetv3_seaweed.pth"
)


# ---------------------------------------------------------
# Training configuration
# ---------------------------------------------------------

BATCH_SIZE = 32

NUM_EPOCHS = 10

LEARNING_RATE = 0.001


# ---------------------------------------------------------
# Device
# ---------------------------------------------------------

DEVICE = torch.device(
    "cuda"
    if torch.cuda.is_available()
    else "cpu"
)


# ---------------------------------------------------------
# Training function
# ---------------------------------------------------------

def train_one_epoch(
    model,
    dataloader,
    criterion,
    optimizer
):

    model.train()

    running_loss = 0.0

    correct_predictions = 0

    total_samples = 0


    for images, labels in dataloader:

        images = images.to(
            DEVICE
        )

        labels = labels.to(
            DEVICE
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


        running_loss += (
            loss.item()
            * images.size(0)
        )


        _, predictions = torch.max(
            outputs,
            dim=1
        )


        correct_predictions += (
            predictions == labels
        ).sum().item()


        total_samples += (
            labels.size(0)
        )


    epoch_loss = (
        running_loss
        / total_samples
    )


    epoch_accuracy = (
        correct_predictions
        / total_samples
    )


    return (
        epoch_loss,
        epoch_accuracy
    )


# ---------------------------------------------------------
# Validation function
# ---------------------------------------------------------

def validate(
    model,
    dataloader,
    criterion
):

    model.eval()


    running_loss = 0.0

    correct_predictions = 0

    total_samples = 0


    with torch.no_grad():

        for images, labels in dataloader:

            images = images.to(
                DEVICE
            )

            labels = labels.to(
                DEVICE
            )


            outputs = model(
                images
            )


            loss = criterion(
                outputs,
                labels
            )


            running_loss += (
                loss.item()
                * images.size(0)
            )


            _, predictions = torch.max(
                outputs,
                dim=1
            )


            correct_predictions += (
                predictions == labels
            ).sum().item()


            total_samples += (
                labels.size(0)
            )


    validation_loss = (
        running_loss
        / total_samples
    )


    validation_accuracy = (
        correct_predictions
        / total_samples
    )


    return (
        validation_loss,
        validation_accuracy
    )


# ---------------------------------------------------------
# Save checkpoint
# ---------------------------------------------------------

def save_checkpoint(
    model,
    optimizer,
    epoch,
    validation_accuracy,
    class_names
):

    checkpoint = {

        "epoch": epoch,

        "model_state_dict":
            model.state_dict(),

        "optimizer_state_dict":
            optimizer.state_dict(),

        "validation_accuracy":
            validation_accuracy,

        "class_names":
            class_names,

        "num_classes":
            len(class_names),

        "architecture":
            "mobilenet_v3_small"
    }


    torch.save(
        checkpoint,
        BEST_MODEL_PATH
    )


# ---------------------------------------------------------
# Main training process
# ---------------------------------------------------------

def train():

    print("=" * 60)

    print(
        "gUSo MobileNetV3 Training"
    )

    print("=" * 60)


    print(
        f"Device: {DEVICE}"
    )


    train_loader, validation_loader, train_dataset = (
        create_dataloaders(
            batch_size=BATCH_SIZE
        )
    )


    class_names = (
        train_dataset.class_names
    )


    num_classes = len(
        class_names
    )


    print(
        f"Classes: {num_classes}"
    )

    print(
        f"Class names: {class_names}"
    )

    print(
        f"Training images: "
        f"{len(train_loader.dataset)}"
    )

    print(
        f"Validation images: "
        f"{len(validation_loader.dataset)}"
    )


    model = build_model(
        num_classes=num_classes,
        freeze_features=True
    )


    model = model.to(
        DEVICE
    )


    criterion = (
        nn.CrossEntropyLoss()
    )


    trainable_parameters = filter(
        lambda parameter:
            parameter.requires_grad,
        model.parameters()
    )


    optimizer = Adam(
        trainable_parameters,
        lr=LEARNING_RATE
    )


    best_validation_accuracy = 0.0


    for epoch in range(
        NUM_EPOCHS
    ):

        print()

        print(
            f"Epoch "
            f"{epoch + 1}"
            f"/"
            f"{NUM_EPOCHS}"
        )

        print("-" * 60)


        train_loss, train_accuracy = (
            train_one_epoch(
                model,
                train_loader,
                criterion,
                optimizer
            )
        )


        validation_loss, validation_accuracy = (
            validate(
                model,
                validation_loader,
                criterion
            )
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


        if (
            validation_accuracy
            > best_validation_accuracy
        ):

            best_validation_accuracy = (
                validation_accuracy
            )


            save_checkpoint(
                model=model,
                optimizer=optimizer,
                epoch=epoch + 1,
                validation_accuracy=
                    validation_accuracy,
                class_names=
                    class_names
            )


            print(
                "Best model saved."
            )


    print()

    print("=" * 60)

    print(
        "Training completed."
    )

    print(
        "Best validation accuracy: "
        f"{best_validation_accuracy * 100:.2f}%"
    )

    print(
        f"Model saved to:\n"
        f"{BEST_MODEL_PATH}"
    )

    print("=" * 60)


if __name__ == "__main__":

    train()