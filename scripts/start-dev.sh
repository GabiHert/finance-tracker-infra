#!/bin/bash

# Start full dev environment (postgres, redis, minio, backend, frontend)
# Usage: ./scripts/start-dev.sh [--build]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRA_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Starting Dev Environment ===${NC}"

# Check for --build flag
BUILD_FLAG=""
if [[ "$1" == "--build" ]]; then
    BUILD_FLAG="--build"
    echo -e "${CYAN}Building images...${NC}"
fi

# Start all containers
echo "Starting containers..."
docker compose up -d $BUILD_FLAG

# Wait for infrastructure services first
echo "Waiting for infrastructure services..."

# Wait for PostgreSQL
echo -n "PostgreSQL: "
until docker exec finance-tracker-postgres pg_isready -U app_user -d finance_tracker > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}Ready${NC}"

# Wait for Redis
echo -n "Redis: "
until docker exec finance-tracker-redis redis-cli -a redis_password ping > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}Ready${NC}"

# Wait for MinIO
echo -n "MinIO: "
until curl -s http://localhost:9010/minio/health/live > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}Ready${NC}"

# Wait for Backend
echo -n "Backend: "
for i in {1..60}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
    if [ $i -eq 60 ]; then
        echo -e " ${RED}Timeout${NC}"
        echo -e "${YELLOW}Check logs: docker logs finance-tracker-backend${NC}"
    fi
done

# Wait for Frontend
echo -n "Frontend: "
for i in {1..60}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
    if [ $i -eq 60 ]; then
        echo -e " ${RED}Timeout${NC}"
        echo -e "${YELLOW}Check logs: docker logs finance-tracker-frontend${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Dev Environment Ready ===${NC}"
echo ""
echo -e "${CYAN}Services:${NC}"
echo "  PostgreSQL: localhost:5433 (user: app_user, db: finance_tracker)"
echo "  Redis:      localhost:6390"
echo "  MinIO API:  localhost:9010"
echo "  MinIO UI:   localhost:9011"
echo "  Backend:    localhost:8080"
echo "  Frontend:   localhost:3000"
echo ""
echo -e "${CYAN}Access the app at:${NC} http://localhost:3000"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  View logs:    docker compose logs -f [service]"
echo "  Rebuild:      ./scripts/start-dev.sh --build"
echo "  Stop:         ./scripts/stop-dev.sh"
echo "  Restart:      ./scripts/restart-dev.sh"
