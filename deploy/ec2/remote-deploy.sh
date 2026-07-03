#!/usr/bin/env bash
set -euo pipefail

# 디렉토리와 무관하게 항상 같은 compose 프로젝트로 인식 (이름 충돌 방지)
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-portfolio}"

COMPOSE_DIR="${COMPOSE_DIR:-/home/ubuntu/my-portfolio}"
MIDO_DEPLOY="${MIDO_DEPLOY:-$COMPOSE_DIR/mido-deploy}"

log() { echo "[mido-deploy] $*"; }

# compose 가 관리하지 않거나 다른 프로젝트 소속인 동명 컨테이너 제거
remove_stale_containers() {
  local svc owner
  for svc in "$@"; do
    if docker ps -a --format '{{.Names}}' | grep -qx "$svc"; then
      owner=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$svc" 2>/dev/null || echo "")
      if [[ -z "$owner" || "$owner" != "$COMPOSE_PROJECT_NAME" ]]; then
        log "  -> $svc owned by '${owner:-none}', removing to avoid name conflict"
        docker rm -f "$svc"
      fi
    fi
  done
}

docker network inspect portfolio-network >/dev/null 2>&1 \
  || docker network create portfolio-network

cd "$COMPOSE_DIR"

main_compose=""
for candidate in docker-compose.yml compose.yml docker-compose.yaml compose.yaml; do
  if [[ -f "$candidate" ]]; then
    main_compose="$candidate"
    break
  fi
done

compose_args=()
if [[ -n "$main_compose" ]]; then
  if docker compose -f "$main_compose" config --services 2>/dev/null | grep -qx 'mido-app'; then
    log "Using overlay: $main_compose + mido-deploy/docker-compose.override.yml"
    compose_args=(-f "$main_compose" -f "$MIDO_DEPLOY/docker-compose.override.yml")
  else
    log "mido-app not in $main_compose — using full MIDO stack"
    compose_args=(-f "$MIDO_DEPLOY/docker-compose.full.yml")
  fi
else
  log "No main compose found — using full MIDO stack"
  compose_args=(-f "$MIDO_DEPLOY/docker-compose.full.yml")
fi

services="$(docker compose "${compose_args[@]}" config --services)"
pull_targets=()
for svc in mido-db mido-app mido-web; do
  if echo "$services" | grep -qx "$svc"; then
    pull_targets+=("$svc")
  fi
done

log "COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
log "Pulling: ${pull_targets[*]}"
docker compose "${compose_args[@]}" pull "${pull_targets[@]}"

log "Removing stale containers with conflicting names (if any)"
remove_stale_containers "${pull_targets[@]}"

log "Starting containers"
docker compose "${compose_args[@]}" up -d "${pull_targets[@]}"

docker image prune -f

if [[ "${SETUP_NGINX:-0}" == "1" ]] && [[ -n "${MIDO_SERVER_NAME:-}" ]]; then
  log "Running nginx setup"
  bash "$MIDO_DEPLOY/setup-nginx.sh"
fi

log "Done"
