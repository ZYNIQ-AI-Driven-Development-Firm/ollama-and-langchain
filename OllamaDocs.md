# Ollama Service Documentation

## Overview
Ollama provides local LLM inference and is used as the core model provider for LangChain in this project.

## Usage
- Runs as a container, internal only
- Exposes port 11434
- Used by API via `OLLAMA_BASE_URL`

## Example API Call
```python
import requests
response = requests.post("http://ollama:11434/api/generate", json={"prompt": "Hello!"})
print(response.json())
```

## Environment Variables
- `OLLAMA_MODELS`: Models to load

## Healthcheck
- `ollama ps` command used for health monitoring
