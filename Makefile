.PHONY: help dev up down logs test

help:
	@echo "Commands:"
	@echo "  dev       : Start services in development mode with hot-reloading."
	@echo "  up        : Start services in detached mode."
	@echo "  down      : Stop services."
	@echo "  logs      : Tail logs from services."
	@echo "  test      : Run tests."
	@echo "  migrate   : Run database migrations."
	@echo "  seed      : Seed the database."

dev:
	docker-compose up

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

test:
	docker-compose run --rm api pytest

migrate:
	docker-compose run --rm api alembic upgrade head

seed:
	docker-compose run --rm api python -m app.seed
