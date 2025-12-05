#!/bin/bash

# Stop and remove dev environment containers
# Usage: ./scripts/stop-dev.sh [-v] (use -v to also remove volumes)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRA_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Stopping Dev Environment ===${NC}"

# Check for -v flag to remove volumes
REMOVE_VOLUMES=""
if [[ "$1" == "-v" ]]; then
    REMOVE_VOLUMES="-v"
    echo -e "${RED}Warning: Volumes will be removed (all data will be lost)${NC}"
fi

# Stop and remove containers
echo "Stopping containers..."
docker compose down $REMOVE_VOLUMES

echo -e "${GREEN}=== Dev Environment Stopped ===${NC}"

if [[ "$1" == "-v" ]]; then
    echo -e "${YELLOW}Volumes have been removed. Database will be fresh on next start.${NC}"
fi
