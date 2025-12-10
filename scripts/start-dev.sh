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

# Check for .env file
if [ ! -f "$INFRA_DIR/.env" ]; then
    echo -e "${YELLOW}No .env file found. Using defaults.${NC}"
    echo -e "${CYAN}To configure email (Resend), copy .env.example to .env:${NC}"
    echo "  cp .env.example .env"
    echo ""
else
    # Source .env file to make variables available
    set -a
    source "$INFRA_DIR/.env"
    set +a

    # Show email configuration status
    if [ -n "$RESEND_API_KEY" ]; then
        echo -e "${GREEN}Email: Resend API configured${NC}"
    else
        echo -e "${YELLOW}Email: Using mock sender (RESEND_API_KEY not set)${NC}"
    fi
fi

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
until curl -s http://localhost:9002/minio/health/live > /dev/null 2>&1; do
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
    if curl -s http://localhost:3100 > /dev/null 2>&1; then
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
echo "  Redis:      localhost:6380"
echo "  MinIO API:  localhost:9002"
echo "  MinIO UI:   localhost:9003"
echo "  Backend:    localhost:8080"
echo "  Frontend:   localhost:3100"
echo ""
echo -e "${CYAN}Email Status:${NC}"
if [ -n "$RESEND_API_KEY" ]; then
    echo -e "  ${GREEN}Resend API: Configured (real emails will be sent)${NC}"
else
    echo -e "  ${YELLOW}Mock mode: Emails queued but not sent (set RESEND_API_KEY in .env)${NC}"
fi
echo ""
echo -e "${CYAN}Access the app at:${NC} http://localhost:3100"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  View logs:    docker compose logs -f [service]"
echo "  Rebuild:      ./scripts/start-dev.sh --build"
echo "  Stop:         ./scripts/stop-dev.sh"
echo "  Restart:      ./scripts/restart-dev.sh"
