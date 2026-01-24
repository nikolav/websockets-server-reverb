#!/usr/bin/env bash
set -euo pipefail

rm -f composer.lock
rm -rf vendor
composer clear-cache

composer install --no-cache

composer validate
composer show
