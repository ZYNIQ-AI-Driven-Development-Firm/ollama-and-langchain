from fastapi import FastAPI, Depends
from prometheus_fastapi_instrumentator import Instrumentator
from .database import engine, Base
from . import models
from .routers import admin, openai
from sqlalchemy.orm import Session
from .database import get_db
from . import crud, schemas
from .config import settings

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

Instrumentator().instrument(app).expose(app)

app.include_router(admin.router, prefix="/admin", tags=["admin"])
app.include_router(openai.router, prefix="/v1", tags=["openai"])

@app.on_event("startup")
def startup_event():
    db = next(get_db())
    # Create admin user if it doesn't exist
    user = crud.get_user_by_email(db, email=settings.ADMIN_EMAIL)
    if not user:
        user_in = schemas.UserCreate(email=settings.ADMIN_EMAIL, password="pass@123")
        crud.create_user(db, user=user_in)
    
    # Pre-pull models
    import os
    models_to_pull = settings.OLLAMA_MODELS.split(',')
    for model in models_to_pull:
        os.system(f"ollama pull {model}")


@app.get("/")
def read_root():
    return {"message": "Ollama Provider is running"}
