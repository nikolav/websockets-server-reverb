#!/usr/bin/env bash
set -euo pipefail

cd /usr/app

# drop stale marker at boot if restart
rm -f /tmp/bootstrapped

# export laravel variables
if [ -f /usr/app/.env ]; then
  set -a
    . /usr/app/.env
  set +a
fi

# warn missing APP_KEY
if [ -z "${APP_KEY:-}" ]; then
    echo "WARNING: APP_KEY is not set. Set it in .env or compose env."
fi

# --- redis doesn't need init ---
# --- postgres init (only if empty) ---
pg_escape_sql_literal() {
  # escape single quotes for SQL string literals: ' -> ''
  printf "%s" "$1" | sed "s/'/''/g"
}
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
  ready=0
  for i in {1..60}; do
    if gosu postgres /usr/bin/pg_isready -h /tmp >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 1
  done

  if [ "$ready" -ne 1 ]; then
    echo "Postgres did not become ready in time"
    kill "$PG_PID" || true
    exit 1
  fi

  # prefer laravel-style db_* env vars as the source of truth
  : "${DB_DATABASE:=app}"
  : "${DB_USERNAME:=app}"
  : "${DB_PASSWORD:=app}"

  # create user/db (use env vars)
  : "${POSTGRES_DB:=$DB_DATABASE}"
  : "${POSTGRES_USER:=$DB_USERNAME}"
  : "${POSTGRES_PASSWORD:=$DB_PASSWORD}"

  # validate identifiers (avoid SQL breakage)
  case "$POSTGRES_USER" in (*[!a-zA-Z0-9_]*|'') echo "Invalid POSTGRES_USER: $POSTGRES_USER"; exit 1;; esac
  case "$POSTGRES_DB" in (*[!a-zA-Z0-9_]*|'') echo "Invalid POSTGRES_DB: $POSTGRES_DB"; exit 1;; esac

  POSTGRES_PASSWORD_ESCAPED="$(pg_escape_sql_literal "$POSTGRES_PASSWORD")"
  gosu postgres psql -h /tmp -v ON_ERROR_STOP=1 --username postgres <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${POSTGRES_USER}') THEN
    CREATE ROLE ${POSTGRES_USER} LOGIN PASSWORD '${POSTGRES_PASSWORD_ESCAPED}';
  END IF;

  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}') THEN
    CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
  END IF;
END
\$\$;
SQL

  gosu postgres /usr/bin/pg_ctl -D /var/lib/postgresql/data -m fast -w stop
  wait "$PG_PID" || true
fi

exec "$@"
