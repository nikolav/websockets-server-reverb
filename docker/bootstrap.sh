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

if [ "${CLEAR_CACHES_ON_BOOT:-true}" = "true" ]; then
  php artisan config:clear || true
  php artisan cache:clear || true
  php artisan route:clear || true
fi

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  # generate migration table:cache if it doesn't exist
  if ! ls database/migrations/*_create_cache_table.php >/dev/null 2>&1; then
    php artisan cache:table
  fi

  php artisan migrate --force || true
fi

touch /tmp/bootstrapped
