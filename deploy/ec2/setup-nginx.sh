#!/usr/bin/env bash
# EC2에서 1회 실행 — MIDO 전용 nginx vhost 설치 (Docker nginx on nginx-network 가정)
set -euo pipefail

MIDO_DEPLOY="${MIDO_DEPLOY:-/home/ubuntu/my-portfolio/mido-deploy}"
MIDO_SERVER_NAME="${MIDO_SERVER_NAME:-}"
NGINX_SITES_AVAILABLE="${NGINX_SITES_AVAILABLE:-/etc/nginx/sites-available}"
NGINX_SITES_ENABLED="${NGINX_SITES_ENABLED:-/etc/nginx/sites-enabled}"

if [[ -z "$MIDO_SERVER_NAME" ]]; then
  echo "MIDO_SERVER_NAME is required (e.g. mido.yourdomain.com)" >&2
  exit 1
fi

if [[ ! -f "$MIDO_DEPLOY/nginx/mido.conf" ]]; then
  echo "Missing $MIDO_DEPLOY/nginx/mido.conf — run deploy first" >&2
  exit 1
fi

sudo mkdir -p "$NGINX_SITES_AVAILABLE" "$NGINX_SITES_ENABLED" /etc/nginx/snippets

sudo sed "s/mido.example.com/${MIDO_SERVER_NAME}/g" \
  "$MIDO_DEPLOY/nginx/mido.conf" \
  | sudo tee "$NGINX_SITES_AVAILABLE/mido" >/dev/null

sudo ln -sf "$NGINX_SITES_AVAILABLE/mido" "$NGINX_SITES_ENABLED/mido"

sudo cp "$MIDO_DEPLOY/nginx/mido-locations.conf" /etc/nginx/snippets/mido-locations.conf

sudo nginx -t
sudo systemctl reload nginx

echo "Nginx configured for server_name=${MIDO_SERVER_NAME}"
