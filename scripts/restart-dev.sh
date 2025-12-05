#!/bin/bash

# Restart dev environment (stop then start)
# Usage: ./scripts/restart-dev.sh [-v] [--build]
#   -v: Remove volumes (fresh database)
#   --build: Rebuild Docker images

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Restarting Dev Environment ===${NC}"
echo ""

# Parse flags
STOP_FLAGS=""
START_FLAGS=""

for arg in "$@"; do
    case $arg in
        -v)
            STOP_FLAGS="-v"
            ;;
        --build)
            START_FLAGS="--build"
            ;;
    esac
done

# Stop
"$SCRIPT_DIR/stop-dev.sh" $STOP_FLAGS

echo ""

# Start
"$SCRIPT_DIR/start-dev.sh" $START_FLAGS
