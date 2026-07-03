#!/usr/bin/env bash
# MIDO 단일 배포 — deploy/ec2/docker-compose.yml 만 사용
set -euo pipefail

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-portfolio}"

# EC2: /home/ubuntu/my-portfolio/deploy/ec2
# 로컬: <repo>/deploy/ec2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
PORTFOLIO="$(cd "${SCRIPT_DIR}/../.." && pwd)"

log() { echo "[mido-deploy] $*"; }

remove_stale_containers() {
  local svc owner
  for svc in "$@"; do
    if docker ps -a --format '{{.Names}}' | grep -qx "$svc"; then
      owner=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$svc" 2>/dev/null || echo "")
      if [[ -z "$owner" || "$owner" != "$COMPOSE_PROJECT_NAME" ]]; then
        log "  -> $svc owned by '${owner:-none}', removing"
        docker rm -f "$svc"
      fi
    fi
  done
}

if [[ ! -f "$COMPOSE_FILE" ]]; then
  log "ERROR: missing $COMPOSE_FILE"
  exit 1
fi

if [[ ! -f "$PORTFOLIO/.env" ]]; then
  log "ERROR: missing $PORTFOLIO/.env (DB_PASSWORD 등)"
  exit 1
fi

cd "$PORTFOLIO"

log "COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
log "compose: $COMPOSE_FILE"

compose=(docker compose -f "$COMPOSE_FILE")

log "Pulling images"
"${compose[@]}" pull

log "Removing stale containers (if any)"
remove_stale_containers mido-db mido-app mido-web portfolio-nginx

log "Starting mido-db mido-app mido-web portfolio-nginx"
"${compose[@]}" up -d

sleep 3

log "Containers:"
docker ps --filter name='mido|portfolio-nginx' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

log "Verify /mido/"
curl -s -o /tmp/mido-check.html -w "HTTP %{http_code}\n" http://127.0.0.1/mido/ || true
if grep -q 'HTTP Status 404' /tmp/mido-check.html 2>/dev/null; then
  log "ERROR: Tomcat 404 on /mido/ — check portfolio-nginx → mido-web"
  docker logs portfolio-nginx --tail=30 || true
  exit 1
fi

log "Verify API"
curl -s -o /tmp/mido-api.html -w "HTTP %{http_code}\n" \
  -X POST http://127.0.0.1/mido/api/verifications/manual \
  -H 'Content-Type: application/json' \
  -d '{"inputType":"PASTE","inputMethod":"TEXTAREA","rawInput":"x","code":"x"}' || true
if grep -q 'HTTP Status 404' /tmp/mido-api.html 2>/dev/null; then
  log "ERROR: Tomcat 404 on API"
  exit 1
fi

docker image prune -f
log "Done"
