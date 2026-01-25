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

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  php /usr/app/artisan migrate --force || true
fi

if [ "${CACHE_ARTISAN:-true}" = "true" ]; then
  php /usr/app/artisan config:cache || true
  php /usr/app/artisan route:cache || true
fi

touch /tmp/bootstrapped
