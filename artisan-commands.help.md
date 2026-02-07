# 🚀 Laravel Artisan Survival Kit (Laravel 12)

A clean, practical **everyday command set** for Laravel development: config, DB, cache, queues, Reverb, routing, and code generation.

---

## 🧭 General / Discoverability

```bash
php artisan about
php artisan list
php artisan help <command>
```

---

## ⚡ Runtime & Debugging

```bash
php artisan env
php artisan serve
php artisan tinker
```

### Quick config sanity (inside Tinker)

```php
config('app.env');
config('app.debug');
config('database.default');
```

---

## 🧹 Config Cache (the #1 “why isn’t it updating?” fix)

### Check if config is cached

```bash
php artisan config:show app
ls bootstrap/cache/config.php
```

### Clear / rebuild

```bash
php artisan config:clear
php artisan config:cache
```

### Inspect key config groups

```bash
php artisan config:show database
php artisan config:show cache
php artisan config:show session
php artisan config:show queue
```

---

## 🗄️ Database & Migrations

### Connection sanity (Tinker)

```php
DB::connection()->getDriverName();
DB::connection()->getDatabaseName();
DB::select("select now()");
```

### Migration workflow

```bash
php artisan migrate
php artisan migrate:status
php artisan migrate:fresh --seed
php artisan migrate:rollback
php artisan db:seed
php artisan db:wipe
```

---

## 🧊 Cache & Redis

### Clear cache

```bash
php artisan cache:clear
php artisan cache:clear --store=redis
php artisan cache:clear --store=file
```

### Verify cache works (Tinker)

```php
Cache::put("ping", "ok", 10);
Cache::get("ping");
```

### Redis sanity (Tinker)

```php
Redis::ping();
Redis::connection()->client();
Redis::connection()->info();
```

---

## 📬 Queues (Workers)

### Check driver (Tinker)

```php
config('queue.default');
```

### Worker control

```bash
php artisan queue:work
php artisan queue:work --tries=3 --timeout=90
php artisan queue:restart
```

### Failed jobs

```bash
php artisan queue:failed
php artisan queue:retry all
php artisan queue:flush
```

---

## 📡 Broadcasting / Reverb

### Check driver (Tinker)

```php
config('broadcasting.default');
config('broadcasting.connections.reverb');
config('broadcasting.connections.reverb.options');
```

### Common “fix it” reset

```bash
php artisan config:clear
php artisan cache:clear
```

---

## 🛣️ Routes

### Inspect routes

```bash
php artisan route:list
php artisan route:list --name=<partial>
php artisan route:list --path=<partial>
```

### Route caching

```bash
php artisan route:clear
php artisan route:cache
```

---

## 🪵 Logs

```bash
tail -f storage/logs/laravel.log
```

### Logging config (Tinker)

```php
config('logging.default');
config('logging.channels');
```

---

## 🧼 Full Reset (Dev Nuclear Option)

```bash
php artisan optimize:clear
```

Equivalent manual clears:

```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan event:clear
```

---

## 🚀 Production Optimization (Deploy)

```bash
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

---

## 📸 Driver Snapshot (One-shot)

```bash
php artisan tinker --execute="
dump([
 'env' => config('app.env'),
 'debug' => config('app.debug'),
 'db' => config('database.default'),
 'cache' => config('cache.default'),
 'queue' => config('queue.default'),
 'session' => config('session.driver'),
 'broadcast' => config('broadcasting.default'),
]);
"
```

---

## 🏗️ Code Generation (make:)

```bash
php artisan make:model Post -mfs
php artisan make:controller PostController --resource --model=Post
php artisan make:request StorePostRequest
php artisan make:resource PostResource
php artisan make:middleware EnsureSomething
php artisan make:event PostCreated
php artisan make:listener SendPostNotifications --event=PostCreated
php artisan make:job ProcessThing
```

---

## 🛡️ Authorization (Policies)

```bash
php artisan make:policy PostPolicy
php artisan make:policy PostPolicy --model=Post
```

---

## ⏱️ Scheduler

```bash
php artisan schedule:work
php artisan schedule:run
```

---

## 📦 Storage & Packages

```bash
php artisan storage:link
php artisan vendor:publish
php artisan vendor:publish --tag=<tag>
```

---

# ✅ Minimal Daily “Survival Set”

```bash
php artisan tinker
php artisan route:list
php artisan migrate
php artisan queue:work
php artisan optimize:clear
php artisan config:cache && php artisan route:cache
```

---

## quick check laravel uses redis for queues
### config sees redis
`
docker exec -it laravel-reverb sh -lc 'php artisan tinker --execute="
dump(config(\"queue.default\"));
dump(config(\"cache.default\"));
"'
`

### worker is running and targets redis
`
docker exec -it laravel-reverb 
 sh -lc 'ps aux | grep -v grep | egrep "queue:work redis"'
`

### dispatch a real job and see done
`docker logs -f laravel-reverb # tail:fallow in 2nd terminal`
`
docker exec -it laravel-reverb 
  sh -lc 'php artisan tinker --execute='
    \App\Jobs\QueueJobsSanityCheck::dispatch()->onQueue("default");
  '

docker logs --tail=50 laravel-reverb | egrep "QueueJobsSanityCheck|RUNNING|DONE"
`
