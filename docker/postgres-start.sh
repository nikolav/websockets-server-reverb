#!/bin/sh
set -eu

DATA_DIR="/var/lib/postgresql/data"

# ensure directory exists, ownership correct
mkdir -p "$DATA_DIR"
chown -R postgres:postgres /var/lib/postgresql

# as postgres user
exec gosu postgres /usr/bin/postgres \
  -D "$DATA_DIR" \
  -c listen_addresses=127.0.0.1 \
  -c logging_collector=on \
  -c log_directory=/var/lib/postgresql/log
