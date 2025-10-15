from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from sqlalchemy.orm import Session
from .. import crud, schemas
from ..database import get_db

api_key_header = APIKeyHeader(name="Authorization")

def get_api_key_from_header(key: str = Depends(api_key_header), db: Session = Depends(get_db)):
    if not key.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme",
        )
    
    token = key.split(" ")[1]
    
    db_key = crud.get_api_key(db, key=token)
    if not db_key or not db_key.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or inactive API key",
        )
    return db_key
