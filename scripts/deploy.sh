#!/usr/bin/env bash
# Deploy latest main to droplet. Run ON the droplet as user `mediku`.
# Usage: bash ~/ppko_bem_fk/scripts/deploy.sh [backend|all]

set -euo pipefail

REPO_DIR="$HOME/ppko_bem_fk"
ENV_FILE=".env.prod"
COMPOSE_FILE="docker-compose.prod.yml"
TARGET="${1:-backend}"

cd "$REPO_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE missing in $REPO_DIR" >&2
  exit 1
fi

echo "==> git pull"
git pull --ff-only

DC="docker compose --env-file $ENV_FILE -f $COMPOSE_FILE"

if [[ "$TARGET" == "all" ]]; then
  echo "==> rebuild full stack"
  $DC up -d --build
else
  echo "==> rebuild backend only"
  $DC up -d --build backend
fi

echo "==> prune dangling images"
docker image prune -f >/dev/null

echo "==> wait for backend health"
for i in {1..30}; do
  status=$($DC ps --format json backend 2>/dev/null | grep -o '"Health":"[^"]*"' | head -1 || true)
  if [[ "$status" == *"healthy"* ]]; then
    echo "    backend healthy"
    break
  fi
  sleep 2
done

echo "==> recent backend logs"
$DC logs --tail=40 backend

echo "==> done"
