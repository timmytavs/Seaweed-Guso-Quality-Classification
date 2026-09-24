import torch.nn as nn

from torchvision.models import (
    mobilenet_v3_small,
    MobileNet_V3_Small_Weights
)


def build_model(
    num_classes: int,
    freeze_features: bool = True
):

    # Load MobileNetV3 with pretrained ImageNet weights
    weights = MobileNet_V3_Small_Weights.DEFAULT

    model = mobilenet_v3_small(
        weights=weights
    )


    # -----------------------------------------------------
    # Freeze feature extractor
    # -----------------------------------------------------

    if freeze_features:

        for parameter in model.features.parameters():

            parameter.requires_grad = False


    # -----------------------------------------------------
    # Replace original 1000-class classifier
    # -----------------------------------------------------

    input_features = (
        model.classifier[3].in_features
    )


    model.classifier[3] = nn.Linear(
        input_features,
        num_classes
    )


    return model


if __name__ == "__main__":

    NUM_CLASSES = 7

    model = build_model(
        num_classes=NUM_CLASSES
    )


    print(model)

    print()

    print(
        "Final output classes:",
        model.classifier[3].out_features
    )