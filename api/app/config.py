from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    POSTGRES_DSN: str
    REDIS_URL: str
    OLLAMA_BASE_URL: str
    JWT_SECRET: str
    OAUTH_CLIENT_ID: str
    OAUTH_CLIENT_SECRET: str
    ADMIN_EMAIL: str
    PROMETHEUS_MULTIPROC_DIR: str
    OLLAMA_MODELS: str

    class Config:
        env_file = ".env"

settings = Settings()
