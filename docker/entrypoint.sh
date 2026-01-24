#!/usr/bin/env bash
set -euo pipefail

cd /usr/app

# Warn if APP_KEY missing
if [ -z "${APP_KEY:-}" ]; then
    echo "WARNING: APP_KEY is not set. Set it in .env or compose env."
fi

# Optional: wait for redis (only if using redis host)
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

# Run migrations only when explicitly enabled
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    echo "Running migrations..."
    php artisan migrate --force
fi

# Cache config/routes (optional, but useful in production)
if [ "${CACHE_ARTISAN:-true}" = "true" ]; then
    php artisan config:cache || true
    php artisan route:cache || true
fi

exec "$@"
