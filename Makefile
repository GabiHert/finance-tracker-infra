# Finance Tracker - Infrastructure Makefile
# Version: 1.1 | Multi-Worktree Support

.PHONY: help up down restart logs ps clean init dev dev-backend dev-frontend wt-info wt-check wt-up wt-down wt-dev wt-clean

# Worktree configuration script
WORKTREE_CONFIG := ../scripts/worktree-config.sh

# Default target
help: ## Show this help message
	@echo "Finance Tracker Infrastructure Commands"
	@echo "======================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Worktree Commands (wt-*):"
	@echo "  Use wt-* commands when running multiple worktrees simultaneously."
	@echo "  Run 'make wt-info' to see your worktree configuration."

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

# =============================================================================
# Multi-Worktree Support
# =============================================================================
# Use these commands (wt-*) when running multiple worktrees simultaneously.
# They auto-detect the worktree and assign unique ports/names.

wt-info: ## Show worktree configuration (ports, names)
	@$(WORKTREE_CONFIG) --info

wt-check: ## Check for port conflicts before starting
	@$(WORKTREE_CONFIG) --check

wt-up: ## Start core services with worktree isolation
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	POSTGRES_PORT=$$INFRA_POSTGRES_PORT \
	REDIS_PORT=$$INFRA_REDIS_PORT \
	MINIO_API_PORT=$$INFRA_MINIO_API_PORT \
	MINIO_CONSOLE_PORT=$$INFRA_MINIO_CONSOLE_PORT \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml up -d postgres minio minio-init redis

wt-down: ## Stop worktree-isolated services
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml down

wt-dev: ## Start dev services with worktree isolation
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	POSTGRES_PORT=$$INFRA_POSTGRES_PORT \
	REDIS_PORT=$$INFRA_REDIS_PORT \
	MINIO_API_PORT=$$INFRA_MINIO_API_PORT \
	MINIO_CONSOLE_PORT=$$INFRA_MINIO_CONSOLE_PORT \
	BACKEND_PORT=$$INFRA_BACKEND_PORT \
	FRONTEND_PORT=$$INFRA_FRONTEND_PORT \
	APP_BASE_URL=http://localhost:$$INFRA_FRONTEND_PORT \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

wt-dev-all: ## Start all dev services with worktree isolation
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	POSTGRES_PORT=$$INFRA_POSTGRES_PORT \
	REDIS_PORT=$$INFRA_REDIS_PORT \
	MINIO_API_PORT=$$INFRA_MINIO_API_PORT \
	MINIO_CONSOLE_PORT=$$INFRA_MINIO_CONSOLE_PORT \
	BACKEND_PORT=$$INFRA_BACKEND_PORT \
	FRONTEND_PORT=$$INFRA_FRONTEND_PORT \
	APP_BASE_URL=http://localhost:$$INFRA_FRONTEND_PORT \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile backend --profile frontend up -d

wt-logs: ## View logs for worktree-isolated services
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml logs -f

wt-ps: ## List worktree-isolated containers
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml ps

wt-clean: ## Clean worktree-isolated services and volumes
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	CONTAINER_PREFIX=$$INFRA_CONTAINER_PREFIX \
	docker-compose -f docker-compose.yml down -v --remove-orphans

wt-health: ## Check health of worktree-isolated services
	@eval "$$($(WORKTREE_CONFIG) --export)" && \
	echo "Checking worktree service health..." && \
	echo "" && \
	echo "Worktree: $$WORKTREE_NAME (offset: $$WORKTREE_OFFSET)" && \
	echo "" && \
	echo "PostgreSQL (port $$INFRA_POSTGRES_PORT):" && \
	(curl -s http://localhost:$$INFRA_POSTGRES_PORT > /dev/null 2>&1 || nc -z localhost $$INFRA_POSTGRES_PORT > /dev/null 2>&1) && echo "  ✓ Port open" || echo "  ✗ Port closed" && \
	echo "" && \
	echo "MinIO API (port $$INFRA_MINIO_API_PORT):" && \
	curl -s -o /dev/null -w "%{http_code}" http://localhost:$$INFRA_MINIO_API_PORT/minio/health/live 2>/dev/null | grep -q "200" && echo "  ✓ Healthy" || echo "  ✗ Unhealthy" && \
	echo "" && \
	echo "Redis (port $$INFRA_REDIS_PORT):" && \
	nc -z localhost $$INFRA_REDIS_PORT > /dev/null 2>&1 && echo "  ✓ Port open" || echo "  ✗ Port closed" && \
	echo "" && \
	echo "Backend (port $$INFRA_BACKEND_PORT):" && \
	curl -s http://localhost:$$INFRA_BACKEND_PORT/health > /dev/null 2>&1 && echo "  ✓ Healthy" || echo "  ✗ Not running" && \
	echo "" && \
	echo "Frontend (port $$INFRA_FRONTEND_PORT):" && \
	curl -s http://localhost:$$INFRA_FRONTEND_PORT > /dev/null 2>&1 && echo "  ✓ Healthy" || echo "  ✗ Not running"
