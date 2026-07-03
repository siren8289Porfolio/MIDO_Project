#!/usr/bin/env bash
# EC2: mido-web 기동 + nginx 를 /mido → mido-web, /mido/api → mido-app 으로 고정
set -euo pipefail

PORTFOLIO="${PORTFOLIO:-/home/ubuntu/my-portfolio}"
SNIPPET="${PORTFOLIO}/deploy/nginx/mido-locations.conf"
WEB_COMPOSE="${PORTFOLIO}/docker-compose.mido-web.yml"

cd "$PORTFOLIO"

log() { echo "[fix-mido] $*"; }

# ── 1. 네트워크 + mido-web ──────────────────────────────────────────────────
docker network inspect portfolio-network >/dev/null 2>&1 \
  || docker network create portfolio-network

if [ -f "$WEB_COMPOSE" ]; then
  log "Starting mido-web"
  docker compose -f "$WEB_COMPOSE" pull mido-web
  docker compose -f "$WEB_COMPOSE" up -d mido-web
fi

# 이미 떠 있는 컨테이너를 portfolio-network 에 연결
for c in mido-web mido-app portfolio-nginx; do
  if docker ps --format '{{.Names}}' | grep -qx "$c"; then
    docker network connect portfolio-network "$c" 2>/dev/null || true
  fi
done

if ! docker ps --format '{{.Names}}' | grep -qx mido-web; then
  log "ERROR: mido-web is not running"
  docker ps -a --filter name=mido
  exit 1
fi

# ── 2. nginx conf 패치 (host + container) ───────────────────────────────────
if [ ! -f "$SNIPPET" ]; then
  log "ERROR: missing $SNIPPET"
  exit 1
fi

LOCATIONS=$(grep -v '^\s*#' "$SNIPPET" | grep -v '^\s*$' || true)

patch_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  python3 - "$file" <<'PY'
from pathlib import Path
import re, sys

conf = Path(sys.argv[1])
snippet = Path("/home/ubuntu/my-portfolio/deploy/nginx/mido-locations.conf")
locations = "\n".join(
    line for line in snippet.read_text().splitlines()
    if line.strip() and not line.strip().startswith("#")
).strip()

text = conf.read_text()
text = re.sub(r"\n?[ \t]*location\s+[^{;\n]*mido[^{;\n]*\{[^{}]*\}", "", text)
if "server {" not in text:
    print(f"skip (no server block): {conf}")
    raise SystemExit(0)
text = re.sub(r"(server\s*\{)", r"\1\n\n" + locations + "\n", text, count=1)
conf.write_text(text)
print(f"patched: {conf}")
PY
}

# host 쪽 conf
for f in \
  "$PORTFOLIO/deploy/nginx/default.conf" \
  "$PORTFOLIO/nginx/default.conf" \
  "$PORTFOLIO/default.conf"
do
  patch_file "$f"
done

# container 안 conf — host volume 미마운트여도 컨테이너 파일을 직접 패치
if docker ps --format '{{.Names}}' | grep -qx portfolio-nginx; then
  INNER_LIST=$(docker exec portfolio-nginx sh -c \
    'grep -rl mido /etc/nginx 2>/dev/null; ls /etc/nginx/conf.d/*.conf 2>/dev/null' | sort -u)
  if [ -z "$INNER_LIST" ]; then
    INNER_LIST="/etc/nginx/conf.d/default.conf"
  fi

  for inner in $INNER_LIST; do
    [ -n "$inner" ] || continue
    if docker exec portfolio-nginx cat "$inner" >"$PORTFOLIO/deploy/nginx/.container-patch.conf" 2>/dev/null; then
      patch_file "$PORTFOLIO/deploy/nginx/.container-patch.conf"
      docker cp "$PORTFOLIO/deploy/nginx/.container-patch.conf" "portfolio-nginx:$inner"
      log "patched inside container: $inner"
    fi
  done

  docker exec portfolio-nginx nginx -t
  docker exec portfolio-nginx nginx -s reload || docker restart portfolio-nginx
  sleep 2
fi

# ── 3. 검증 ────────────────────────────────────────────────────────────────
log "Containers:"
docker ps --filter name=mido --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker ps --filter name=portfolio-nginx --format 'table {{.Names}}\t{{.Status}}'

log "Direct Next (mido-web:3000/mido/):"
curl -s -o /tmp/mido-direct.html -w "HTTP %{http_code}\n" http://127.0.0.1:3000/mido/ 2>/dev/null \
  || docker exec mido-web wget -q -O - http://127.0.0.1:3000/mido/ 2>/dev/null | head -c 200 || true

log "Via nginx /mido/:"
curl -s -o /tmp/mido-nginx.html -w "HTTP %{http_code}\n" http://127.0.0.1/mido/ || true
if grep -q 'HTTP Status 404' /tmp/mido-nginx.html 2>/dev/null; then
  log "ERROR: still Tomcat 404 — nginx is proxying /mido to mido-app"
  log "nginx mido lines (host):"
  grep -n mido "$PORTFOLIO/deploy/nginx/default.conf" 2>/dev/null || true
  log "nginx mido lines (container):"
  docker exec portfolio-nginx sh -c 'grep -rn mido /etc/nginx 2>/dev/null' || true
  exit 1
fi

if grep -qi 'mido\|<!DOCTYPE html>' /tmp/mido-nginx.html 2>/dev/null; then
  log "OK: /mido/ is not Tomcat 404"
else
  log "WARN: unexpected body (first 200 bytes):"
  head -c 200 /tmp/mido-nginx.html 2>/dev/null || true
  echo
fi

log "API prefix strip test (expect 201 or 400, not Tomcat HTML):"
curl -s -o /tmp/mido-api.html -w "HTTP %{http_code}\n" \
  -X POST http://127.0.0.1/mido/api/verifications/manual \
  -H 'Content-Type: application/json' \
  -d '{"inputType":"PASTE","inputMethod":"TEXTAREA","rawInput":"x","code":"x"}' || true
if grep -q 'HTTP Status 404' /tmp/mido-api.html 2>/dev/null; then
  log "ERROR: API still Tomcat 404 — /mido/api prefix not stripped"
  exit 1
fi

log "Done"
