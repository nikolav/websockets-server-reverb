#!/bin/sh
set -eu

DATA_DIR="/var/lib/postgresql/data"
LOG_DIR="/var/lib/postgresql/log"

# ensure directories exist, ownership correct
mkdir -p "$DATA_DIR" "$LOG_DIR"
chown -R postgres:postgres /var/lib/postgresql

# run as postgres user
exec gosu postgres /usr/bin/postgres \
  -D "$DATA_DIR" \
  -c listen_addresses=127.0.0.1
