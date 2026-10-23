
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "gUSo Seaweed Quality Classification API"

    DATABASE_URL: str

    MODEL_PATH: str = "app/ml/weights/species_mobilenetv3_best.pth"

    MAX_IMAGE_SIZE: int = 5 * 1024 * 1024

    ALLOWED_IMAGE_TYPES: list[str] = [
        "image/jpeg",
        "image/png",
    ]

    # Local presentation mode
    guso_demo_mode: bool = False

    # JWT authentication key
    JWT_SECRET_KEY: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )


settings = Settings()
