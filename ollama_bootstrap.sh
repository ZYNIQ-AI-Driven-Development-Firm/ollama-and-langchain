#!/bin/sh
set -e

ollama serve &

sleep 5

# Pull models from environment variable
for model in $(echo $OLLAMA_MODELS | tr "," " "); do
  ollama pull $model
done

wait
