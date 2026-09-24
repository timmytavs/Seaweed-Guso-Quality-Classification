from pydantic_settings import BaseSettings


class Settings(BaseSettings):

    APP_NAME: str = "gUSo Seaweed Quality Classification API"
    
    DATABASE_URL: str

    MODEL_PATH: str = (
        "app/ml/weights/species_mobilenetv3_best.pth"
    )

    MAX_IMAGE_SIZE: int = 5 * 1024 * 1024

    ALLOWED_IMAGE_TYPES: list[str] = [
        "image/jpeg",
        "image/png"
    ]
    
    


    class Config:
        env_file = ".env"



settings = Settings()