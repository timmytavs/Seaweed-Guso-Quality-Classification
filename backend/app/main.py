
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router


app = FastAPI(
    title="gUSo API",
    version="1.0.0"
)

# Allow the configured VS Code frontend tunnel.
tunnel_origin = os.getenv("GUSO_FRONTEND_ORIGIN", "").strip().rstrip("/")

allowed_origins = [tunnel_origin] if tunnel_origin else []

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(api_router)
