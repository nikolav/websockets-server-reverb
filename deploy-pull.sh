#!/usr/bin/env bash
set -euo pipefail

docker pull 0imbn7v6rkw/websockets-server-reverb && \
docker stop laravel-reverb || true && \
docker rm laravel-reverb || true && \
docker run -d \
  --name laravel-reverb \
  -p 127.0.0.1:8080:8080 \
  --env-file ./.env \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e REDIS_HOST=redis \
  -e DB_HOST=postgres \
  -e CACHE_STORE=redis \
  -e QUEUE_CONNECTION=redis \
  -e SESSION_DRIVER=redis \
  -e BROADCAST_CONNECTION=reverb \
  -e RUN_MIGRATION=true \
  -e CACHE_ARTISAN=true \
  --pull=always \
  --restart unless-stopped \
  0imbn7v6rkw/websockets-server-reverb

docker ps -a
docker logs --tail=122 laravel-reverb

# docker compose down -v --rmi all --remove-orphans
# docker system prune --all --volumes --force
