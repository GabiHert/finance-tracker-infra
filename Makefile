# Finance Tracker - Infrastructure Makefile
# Version: 1.0 | Milestone 1

.PHONY: help up down restart logs ps clean init dev dev-backend dev-frontend

# Default target
help: ## Show this help message
	@echo "Finance Tracker Infrastructure Commands"
	@echo "======================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Core Services (PostgreSQL, MinIO, Redis)
# =============================================================================

up: ## Start all core services (postgres, minio, redis)
	docker-compose up -d

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## View logs from all services
	docker-compose logs -f

ps: ## List running containers
	docker-compose ps

# =============================================================================
# Development Mode
# =============================================================================

dev: ## Start all services with development overrides
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

dev-backend: ## Start services with backend (hot reload)
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile backend up -d

dev-frontend: ## Start services with frontend
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile frontend up -d

dev-all: ## Start all services including backend and frontend
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile backend --profile frontend up -d

# =============================================================================
# Database Management
# =============================================================================

db-shell: ## Open PostgreSQL shell
	docker-compose exec postgres psql -U $${POSTGRES_USER:-app_user} -d $${POSTGRES_DB:-finance_tracker}

db-logs: ## View PostgreSQL logs
	docker-compose logs -f postgres

# =============================================================================
# MinIO Management
# =============================================================================

minio-console: ## Open MinIO console URL
	@echo "MinIO Console: http://localhost:9001"
	@echo "Default credentials: minioadmin / minioadmin123"

minio-logs: ## View MinIO logs
	docker-compose logs -f minio

# =============================================================================
# Redis Management
# =============================================================================

redis-cli: ## Open Redis CLI
	docker-compose exec redis redis-cli -a $${REDIS_PASSWORD:-redis_password}

redis-logs: ## View Redis logs
	docker-compose logs -f redis

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Stop and remove all containers, networks, and volumes
	docker-compose down -v --remove-orphans

clean-all: ## Remove everything including images
	docker-compose down -v --rmi all --remove-orphans

# =============================================================================
# Health Checks
# =============================================================================

health: ## Check health status of all services
	@echo "Checking service health..."
	@echo ""
	@echo "PostgreSQL:"
	@docker-compose exec -T postgres pg_isready -U $${POSTGRES_USER:-app_user} -d $${POSTGRES_DB:-finance_tracker} && echo "  ✓ Healthy" || echo "  ✗ Unhealthy"
	@echo ""
	@echo "MinIO:"
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/minio/health/live | grep -q "200" && echo "  ✓ Healthy" || echo "  ✗ Unhealthy"
	@echo ""
	@echo "Redis:"
	@docker-compose exec -T redis redis-cli -a $${REDIS_PASSWORD:-redis_password} ping 2>/dev/null | grep -q "PONG" && echo "  ✓ Healthy" || echo "  ✗ Unhealthy"

# =============================================================================
# Initialization
# =============================================================================

init: ## Initialize infrastructure for first time setup
	@echo "Initializing Finance Tracker infrastructure..."
	@cp -n .env.example .env 2>/dev/null || true
	@echo "✓ Environment file ready"
	@docker-compose pull
	@echo "✓ Docker images pulled"
	@docker-compose up -d
	@echo "✓ Services started"
	@echo ""
	@echo "Infrastructure is ready!"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - MinIO API:  localhost:9000"
	@echo "  - MinIO UI:   localhost:9001"
	@echo "  - Redis:      localhost:6379"
