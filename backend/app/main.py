# app/main.py
# pyrefly: ignore [missing-import]
from fastapi import FastAPI

app = FastAPI(title="Guso Quality Classification API")

@app.get("/")
def root():
    return {
        "message": "Guso Quality Classification API is running"
        }