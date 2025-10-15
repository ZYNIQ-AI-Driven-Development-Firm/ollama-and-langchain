from pydantic import BaseModel
from typing import List, Optional
import datetime

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    role: str
    class Config:
        orm_mode = True

class APIKeyCreate(BaseModel):
    notes: Optional[str] = None
    allowed_models: Optional[str] = "*"
    concurrency_limit: Optional[int] = 10
    rate_limit_rpm: Optional[int] = 1000
    monthly_budget: Optional[float] = None

class APIKey(APIKeyCreate):
    id: int
    hashed_key: str
    owner_id: int
    created_at: datetime.datetime
    last_used: Optional[datetime.datetime]
    is_active: bool

    class Config:
        orm_mode = True

class ModelBase(BaseModel):
    name: str
    alias: str
    backend_tag: str
    enabled: bool

class ModelCreate(ModelBase):
    pass

class Model(ModelBase):
    id: int
    class Config:
        orm_mode = True

class AppBase(BaseModel):
    name: str

class AppCreate(AppBase):
    pass

class App(AppBase):
    id: int
    owner_id: int
    class Config:
        orm_mode = True
