# API Service Documentation

## Overview
The API service is built with FastAPI and integrates LangChain and Ollama for LLM-powered endpoints.

## Main Endpoints
- `/chat`: Accepts user input, processes with LangChain/Ollama, returns response.
- `/health`: Health check endpoint.

## Environment Variables
- `POSTGRES_DSN`: Postgres connection string
- `REDIS_URL`: Redis connection string
- `OLLAMA_BASE_URL`: Ollama service URL
- `JWT_SECRET`, `OAUTH_CLIENT_ID`, etc.

## Example Usage
```python
from fastapi import FastAPI
from langchain.llms import Ollama

app = FastAPI()
ollama_llm = Ollama(base_url="http://ollama:11434")

@app.post("/chat")
def chat(input: str):
    return ollama_llm(input)
```

## Dependencies
- FastAPI
- LangChain
- Ollama
