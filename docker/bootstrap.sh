#!/bin/sh
set -eu

# wait up to 60s for pg + redis
ok=0
i=1
while [ "$i" -le 60 ]; do
  if nc -z 127.0.0.1 5432 >/dev/null 2>&1 && nc -z 127.0.0.1 6379 >/dev/null 2>&1; then
    ok=1
    break
  fi
  i=$((i+1))
  sleep 1
done

if [ "$ok" -ne 1 ]; then
  echo "bootstrap: pg/redis not ready" >&2
  exit 1
fi

if [ "${DOCKER_BUILD_NO_CACHE:-true}" = "true" ]; then
  php artisan config:clear || true
  php artisan route:clear || true
  php artisan optimize:clear || true
fi

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  php /usr/app/artisan migrate --force || true
fi

touch /tmp/bootstrapped
