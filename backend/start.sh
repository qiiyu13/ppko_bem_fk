#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ "${NODE_ENV:-}" = "production" ]; then
  echo "ERROR: start.sh is for development only. Use docker compose for production."
  exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[start]${NC} $1"; }
warn() { echo -e "${YELLOW}[start]${NC} $1"; }

# 1. Start PostgreSQL via Docker Compose
log "Starting PostgreSQL..."
docker compose -f "$SCRIPT_DIR/../docker-compose.yml" up -d

# Wait for Postgres to be ready
log "Waiting for PostgreSQL to accept connections..."
until docker exec mediku-postgres pg_isready -U mediku -d mediku &>/dev/null; do
  sleep 1
done
log "PostgreSQL is ready"

# 2. Install dependencies if needed
if [ ! -d "node_modules" ]; then
  log "Installing dependencies..."
  npm install
fi

# 3. Run Prisma migrations
log "Running Prisma migrations..."
npx prisma migrate dev

# 4. Seed the database (skip if already seeded)
USER_COUNT=$(docker exec mediku-postgres psql -U mediku -d mediku -tAc "SELECT COUNT(*) FROM \"User\";" 2>/dev/null || echo "0")
if [ "$USER_COUNT" = "0" ]; then
  log "Seeding database..."
  npm run prisma:seed
else
  log "Database already seeded (${USER_COUNT} users found), skipping."
fi

# 5. Start the backend server
log "Starting backend server..."
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Backend is running!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "  API:  http://localhost:3000/api/v1"
echo ""
echo "  Login credentials:"
  echo "    SUPERADMIN:  username=superadmin.wati  pw=Mediku@2026!"
  echo "    SUPERADMIN:  username=superadmin.aidut pw=Mediku@2026!"
  echo "    SUPERADMIN:  username=superadmin.qyu   pw=Mediku@2026!"
  echo "    PATIENT:     KK=3275000000000003       pw=patient123"
echo ""
echo "  Press Ctrl+C to stop the server."
echo ""

npx nodemon src/index.js