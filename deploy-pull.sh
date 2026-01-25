#!/usr/bin/env bash
set -euo pipefail

IMAGE="0imbn7v6rkw/websockets-server-reverb:1.0.0"
NAME="laravel-reverb"

docker run -d \
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
  -e RUN_MIGRATIONS="true" \
  -e CACHE_ARTISAN="true" \
  -v pgdata:/var/lib/postgresql/data \
  -v redisdata:/data \
  --pull=always \
  --stop-timeout 60 \
  --restart unless-stopped \
  "$IMAGE"

docker logs --tail=122 "$NAME"

## runtime debug checklist
# docker exec -it laravel-reverb ps aux
# docker exec -it laravel-reverb ss -ltnp | egrep "8080|5432|6379"
# docker exec -it laravel-reverb php -r 'echo "redis ping: "; var_dump(Illuminate\Support\Facades\Redis::connection()->ping());'
# docker exec -it laravel-reverb php artisan tinker --execute="DB::select('select 1 as ok');"
# wscat -c "ws://127.0.0.1:8080/app/$REVERB_APP_KEY?protocol=7&client=js&version=8.4.0&flash=false"
# docker exec -it laravel-reverb which postgres initdb pg_isready psql
