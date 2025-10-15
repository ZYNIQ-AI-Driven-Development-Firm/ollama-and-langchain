from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import crud, schemas, models
from ..database import get_db
import secrets

router = APIRouter()

@router.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@router.post("/keys/", response_model=schemas.APIKey)
def create_api_key(key: schemas.APIKeyCreate, db: Session = Depends(get_db)):
    # For now, create keys for the first user (admin)
    user = db.query(models.User).first()
    if not user:
        raise HTTPException(status_code=404, detail="Admin user not found")
    
    new_key = secrets.token_urlsafe(32)
    db_key, _ = crud.create_api_key(db, key=new_key, owner_id=user.id, key_create=key)
    
    # Return the key in a custom response, as it's only shown once
    return {**db_key.__dict__, "key": new_key}


@router.get("/models/", response_model=list[schemas.Model])
def get_models(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    models = crud.get_models(db, skip=skip, limit=limit)
    return models

@router.post("/models/", response_model=schemas.Model)
def create_model(model: schemas.ModelCreate, db: Session = Depends(get_db)):
    return crud.create_model(db=db, model=model)
