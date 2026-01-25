FROM php:8.3-cli-alpine

RUN set -eux; \
  apk add --no-cache \
    bash curl tzdata coreutils netcat-openbsd iproute2 \
    supervisor \
    gosu \
    # redis server
    redis \
    # postgres server + client
    postgresql \
    postgresql-contrib \
    icu-libs oniguruma libzip postgresql-libs; \
  \
  apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    icu-dev oniguruma-dev libzip-dev postgresql-dev; \
  \
  docker-php-ext-install -j"$(nproc)" \
    intl mbstring zip opcache pdo pdo_pgsql pcntl; \
  \
  pecl install igbinary redis; \
  docker-php-ext-enable igbinary redis; \
  rm -rf /tmp/pear; \
  \
  apk del .build-deps

# required directories
RUN mkdir -p \
    /var/log/supervisor \
    /usr/app \
    /usr/app/storage \
    /usr/app/bootstrap/cache \
    /run

# entrypoint scrypt
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# supervisor.bootstrap scrypt
COPY docker/bootstrap.sh /usr/local/bin/bootstrap.sh
RUN chmod +x /usr/local/bin/bootstrap.sh

# postgres:start scrypt
COPY docker/postgres-start.sh /usr/local/bin/postgres-start.sh
RUN chmod +x /usr/local/bin/postgres-start.sh

WORKDIR /usr/app

# install composer deps
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock ./
RUN composer install \
  --no-dev \
  --no-interaction \
  --prefer-dist \
  --optimize-autoloader \
  --no-scripts \
  --no-progress

# copy app
COPY . .

# run the scripts now that artisan exists (package discovery, etc.)
RUN composer run-script post-autoload-dump --no-interaction

# add supervisor config
COPY docker/supervisord.conf /etc/supervisord.conf

# Volumes for stateful services
VOLUME ["/var/lib/postgresql/data", "/data"]

# ✅ postgres + redis + migrations + cache done
# ✅ reverb socket is accepting connections
HEALTHCHECK --interval=10s --timeout=2s --start-period=30s --retries=3 \
  CMD \
    test -f /tmp/bootstrapped \
    && nc -z 127.0.0.1 8080 \
    || exit 1

# reverb listens here
EXPOSE 8080 5432 6379

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
