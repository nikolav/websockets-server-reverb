#!/usr/bin/env bash
set -euo pipefail

cd /usr/app

# warn missing APP_KEY
if [ -z "${APP_KEY:-}" ]; then
    echo "WARNING: APP_KEY is not set. Set it in .env or compose env."
fi

# --- redis doesn't need init ---
# --- postgres init (only if empty) ---
if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
  echo "Initializing Postgres data dir..."
  mkdir -p /var/lib/postgresql/data
  chown -R postgres:postgres /var/lib/postgresql

  # initdb
  gosu postgres /usr/bin/initdb -D /var/lib/postgresql/data

  # start temporary postgres to create user/db
  gosu postgres /usr/bin/postgres -D /var/lib/postgresql/data -k /tmp &
  PG_PID=$!

  # wait for pg
  for i in {1..60}; do
    gosu postgres /usr/bin/pg_isready -h /tmp >/dev/null 2>&1 && break
    sleep 1
  done

  # create user/db (use env vars)
  : "${POSTGRES_DB:=app}"
  : "${POSTGRES_USER:=app}"
  : "${POSTGRES_PASSWORD:=secret}"

  gosu postgres psql -h /tmp -v ON_ERROR_STOP=1 --username postgres <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${POSTGRES_USER}') THEN
    CREATE ROLE ${POSTGRES_USER} LOGIN PASSWORD '${POSTGRES_PASSWORD}';
  END IF;
END
\$\$;
CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
SQL

  kill "$PG_PID"
  wait "$PG_PID" || true
fi

# wait for redis
if [ -n "${REDIS_HOST:-}" ]; then
    echo "Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."

    for i in $(seq 1 30); do
        if nc -z "${REDIS_HOST}" "${REDIS_PORT:-6379}" >/dev/null 2>&1; then
            echo "Redis is up."
            break
        fi
        sleep 1
    done
fi

# wait for postgres
echo "Waiting for Postgres on 127.0.0.1:5432..."
for i in $(seq 1 30); do
  if nc -z 127.0.0.1 5432 >/dev/null 2>&1; then
    echo "Postgres is up."
    break
  fi
  sleep 1
done

sleep 1

# run migrations if explicitly enabled
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    echo "Running migrations..."
    php artisan migrate --force || true
fi

# cache config/routes
if [ "${CACHE_ARTISAN:-true}" = "true" ]; then
    php artisan config:cache || true
    php artisan route:cache || true
fi

exec "$@"
