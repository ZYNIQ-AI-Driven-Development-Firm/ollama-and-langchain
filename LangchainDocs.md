# LangChain Integration Documentation

## Overview
This project uses LangChain in the backend API to orchestrate LLM workflows, manage memory, and integrate external tools and data sources.

## Installation
Add to `api/requirements.txt`:
```
langchain
```

## Usage
- Chains and agents for advanced LLM orchestration
- Memory modules for context retention
- Integration with Ollama via API
- Example usage in `api/main.py`:
```python
from langchain.llms import Ollama
from langchain.chains import LLMChain

ollama_llm = Ollama(base_url="http://ollama:11434")
chain = LLMChain(llm=ollama_llm, prompt="What is LangChain?")
result = chain.run()
print(result)
```

## Features Used
- LLMChain
- Ollama integration
- Prompt templates
- (Add more as you expand)
