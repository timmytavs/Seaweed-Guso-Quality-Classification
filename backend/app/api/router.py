from fastapi import APIRouter

from app.api.routes import health
from app.api.routes import history
from app.api.routes import classifications


api_router = APIRouter()


api_router.include_router(
    health.router
)

api_router.include_router(
    history.router
)

api_router.include_router(
    classifications.router
)