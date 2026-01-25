#!/usr/bin/env bash
set -euo pipefail

echo "🧹 Cleaning Composer state..."
rm -rf vendor composer.lock
composer clear-cache

echo "📦 Resolving dependencies from scratch..."
composer update --no-interaction --prefer-dist

echo "🔍 Validating install..."
composer validate
composer show
