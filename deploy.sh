#!/usr/bin/env bash
set -euo pipefail

IMAGE="0imbn7v6rkw/websockets-server-reverb:1.0.0"
NAME="laravel-reverb"

docker rm -f "$NAME" >/dev/null 2>&1 || true \
&& docker run -d \
  --name "$NAME" \
  -p 127.0.0.1:8080:8080 \
  --env-file ./.env \
  -e APP_ENV=production \
  -e APP_DEBUG="false" \
  -e REDIS_HOST=127.0.0.1 \
  -e DB_HOST=127.0.0.1 \
  -e CACHE_STORE=redis \
  -e QUEUE_CONNECTION=redis \
  -e SESSION_DRIVER=redis \
  -e BROADCAST_CONNECTION=reverb \
  -e CLEAR_CACHES_ON_BOOT="true" \
  -e RUN_MIGRATIONS="true" \
  -v pgdata:/var/lib/postgresql/data \
  -v redisdata:/data \
  --pull=always \
  --stop-timeout 60 \
  --restart unless-stopped \
  "$IMAGE"

# docker rm -f laravel-reverb
# docker system prune --all --volumes --force
# docker volume rm pgdata redisdata
