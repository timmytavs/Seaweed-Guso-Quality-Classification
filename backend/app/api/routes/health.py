from fastapi import APIRouter


router = APIRouter(
    prefix="/health",
    tags=["Health"]
)


@router.get("/")
def health_check():

    return {
        "status": "healthy",
        "service": "gUSo API is running",
        "message": "Backend is running"
    }