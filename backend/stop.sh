#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[stop]${NC} $1"; }

# 1. Kill any running Node/Nodemon processes on port 3000
SERVER_PID=$(lsof -ti:3000 2>/dev/null || true)
if [ -n "$SERVER_PID" ]; then
  log "Stopping backend server (PID: $SERVER_PID)..."
  kill $SERVER_PID 2>/dev/null || true
else
  log "No backend server running on port 3000"
fi

# 2. Stop PostgreSQL via Docker Compose
log "Stopping PostgreSQL..."
docker compose -f "$SCRIPT_DIR/../docker-compose.yml" down

echo ""
echo -e "${CYAN}Backend fully stopped.${NC}"