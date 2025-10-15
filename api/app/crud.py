from sqlalchemy.orm import Session
from . import models, schemas
from passlib.context import CryptContext
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_api_key(db: Session, key: str, owner_id: int, key_create: schemas.APIKeyCreate):
    hashed_key = hashlib.sha256(key.encode()).hexdigest()
    db_key = models.APIKey(
        hashed_key=hashed_key,
        owner_id=owner_id,
        **key_create.dict()
    )
    db.add(db_key)
    db.commit()
    db.refresh(db_key)
    return db_key, key

def get_api_key(db: Session, key: str):
    hashed_key = hashlib.sha256(key.encode()).hexdigest()
    return db.query(models.APIKey).filter(models.APIKey.hashed_key == hashed_key).first()

def get_models(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Model).offset(skip).limit(limit).all()

def create_model(db: Session, model: schemas.ModelCreate):
    db_model = models.Model(**model.dict())
    db.add(db_model)
    db.commit()
    db.refresh(db_model)
    return db_model
