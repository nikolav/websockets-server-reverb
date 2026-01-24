# Laravel Reverb WebSocket Server

This repository hosts a **dedicated Laravel Reverb server**, designed to provide realtime WebSocket broadcasting for one or more Laravel applications.

It is **not** a traditional web application. Instead, it runs Reverb as an infrastructure service (similar to Redis or Postgres) and is typically deployed behind an HTTPS reverse proxy (Nginx).

---

## What this project is

- A **standalone Reverb WebSocket server**
- Runs via `php artisan reverb:start`
- Pusher-compatible broadcasting endpoint
- Optimized for containerized / server deployments
- Intended to be shared by multiple Laravel apps

---

## What this project is *not*

- ❌ A public-facing Laravel website
- ❌ An API backend
- ❌ A Blade / MVC application

The default Laravel HTTP routes (including `/`) are unused and replaced with a minimal placeholder page.

---

## Typical architecture

```
Clients (Browser / Mobile)
        |
        |  wss://reverb.your-domain.com
        v
     Nginx (TLS)
        |
        |  http://127.0.0.1:8080
        v
 Laravel Reverb Server
        |
        |  Redis / Queues
        v
     Redis / Postgres
```

---

## Key technologies

- **Laravel Reverb** — realtime WebSocket server
- **Redis** — queues, cache, pub/sub
- **PostgreSQL** — optional persistence
- **Docker & Docker Compose**
- **Nginx** — TLS termination and reverse proxy

---

## Environment setup

Copy the example environment file and generate an app key:

```bash
cp .env.example .env
php artisan key:generate
```

Configure Reverb-related variables:

```env
REVERB_SCHEME=https
REVERB_HOST=reverb.your-domain.com
REVERB_PORT=443
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
```

---

## Running the server

The Reverb server is started using Supervisor:

```bash
php artisan reverb:start --host=0.0.0.0 --port=8080
```

In production, this is typically managed inside a Docker container and kept alive by Supervisor.

---

## Health checks

The service exposes a TCP listener on port `8080`.  
A simple health check:

```bash
nc -z 127.0.0.1 8080
```

or

```bash
php -r "exit(@fsockopen('127.0.0.1', 8080) ? 0 : 1);"
```

---

## Security notes

- Port `8080` should **not** be publicly exposed
- Always run behind HTTPS (`wss://`) using Nginx or similar
- Publishing events requires signed credentials (Pusher protocol)
- Firewall should allow only `22`, `80`, and `443`

---

## License

This project is open-sourced software licensed under the MIT license.

Laravel itself is © Taylor Otwell and contributors.
