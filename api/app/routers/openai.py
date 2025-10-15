from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from .. import crud, schemas
from ..database import get_db
from ..security import get_api_key_from_header
import httpx
from ..config import settings
import json

router = APIRouter()

@router.post("/chat/completions")
async def chat_completions(request: Request, db: Session = Depends(get_db), api_key: schemas.APIKey = Depends(get_api_key_from_header)):
    body = await request.json()
    model_alias = body.get("model")
    
    # Get model from alias
    model = db.query(schemas.Model).filter(schemas.Model.alias == model_alias).first()
    if not model:
        raise HTTPException(status_code=404, detail=f"Model alias '{model_alias}' not found")

    # Check if key is allowed to use model
    if model.alias not in api_key.allowed_models.split(',') and api_key.allowed_models != '*':
        raise HTTPException(status_code=403, detail=f"API key not allowed to use model '{model_alias}'")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.OLLAMA_BASE_URL}/api/chat",
            json={"model": model.backend_tag, "messages": body.get("messages"), "stream": body.get("stream", False)},
            timeout=None,
        )
    
    return response.json()


@router.get("/models")
def get_models(db: Session = Depends(get_db)):
    models = crud.get_models(db)
    return {"data": models}
