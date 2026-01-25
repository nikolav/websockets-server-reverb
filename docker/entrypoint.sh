#!/usr/bin/env bash
set -euo pipefail

cd /usr/app

# warn missing APP_KEY
if [ -z "${APP_KEY:-}" ]; then
    echo "WARNING: APP_KEY is not set. Set it in .env or compose env."
fi

# drop stale marker at boot if restart
rm -f /tmp/bootstrapped

# --- redis doesn't need init ---
# --- postgres init (only if empty) ---
if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
  echo "Initializing Postgres data dir..."
  mkdir -p /var/lib/postgresql/data

  # ensure postgres user exists
  id postgres >/dev/null 2>&1 || { echo "postgres user missing"; exit 1; }
  chown -R postgres:postgres /var/lib/postgresql

  # initdb
  gosu postgres /usr/bin/initdb \
    -D /var/lib/postgresql/data \
    --auth-local=trust \
    --auth-host=scram-sha-256 \
    --encoding=UTF8 \
    --locale=C

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

exec "$@"
