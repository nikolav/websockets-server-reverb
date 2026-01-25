#!/bin/sh
set -eu

DATA_DIR="/var/lib/postgresql/data"
LOG_DIR="/var/lib/postgresql/log"
RUN_DIR="/run/postgresql"

# ensure directories exist, ownership correct
mkdir -p "$DATA_DIR" "$LOG_DIR" "$RUN_DIR"
chown -R postgres:postgres /var/lib/postgresql
chown -R postgres:postgres /run/postgresql

# run as postgres user
exec gosu postgres /usr/bin/postgres \
  -D "$DATA_DIR" \
  -c listen_addresses=127.0.0.1 \
  -c unix_socket_directories=/run/postgresql
