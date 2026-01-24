FROM php:8.3-cli-alpine

RUN set -eux; \
  apk add --no-cache \
    bash curl tzdata \
    supervisor \
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

WORKDIR /usr/app

# Copy app (adjust to your build flow)
COPY . /usr/app

# (Optional) install composer deps during build if you want
# COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Supervisor config
COPY docker/supervisord.conf /etc/supervisord.conf

# Reverb listens here (you can change)
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
