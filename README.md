# Laravel Reverb WebSocket Server

This repository provides a **dedicated Laravel Reverb WebSocket service** intended to run as shared infrastructure for one or more Laravel applications.

It is **not a traditional web app**. Instead, it runs Laravel Reverb as a long‑lived background service (similar to Redis or Postgres) and is exposed publicly **only via HTTPS / WSS** behind an Nginx reverse proxy.

---

## What this project is

- ✅ Standalone **Laravel Reverb** WebSocket server
- ✅ Pusher‑compatible realtime broadcasting endpoint
- ✅ Designed for **infrastructure / service deployment**
- ✅ Can be shared by multiple Laravel applications
- ✅ Optimized for Docker + Supervisor setups

---

## What this project is not

- ❌ A public Laravel website
- ❌ An API backend
- ❌ A Blade / MVC application

The default Laravel HTTP layer is intentionally unused.

---

## Typical architecture

```text
Browser / Mobile Clients
        |
        |  wss://reverb.your-domain.com
        v
     Nginx (TLS termination)
        |
        |  http://127.0.0.1:8080
        v
  Laravel Reverb Server
        |
        |  Pub/Sub, queues, state
        v
     Redis / PostgreSQL
```

---

## Core technologies

- **Laravel Reverb** — WebSocket server (Pusher protocol)
- **Redis** — pub/sub, queues, cache
- **PostgreSQL** — optional persistence
- **Nginx** — TLS termination + reverse proxy
- **Docker & Docker Compose**
- **Supervisor** — process management

---

## Environment setup

Copy the example environment file and generate an application key:

```bash
cp .env.example .env
php artisan key:generate
```

Configure Reverb:

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=1
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret

REVERB_HOST=reverb.your-domain.com
REVERB_PORT=443
REVERB_SCHEME=https
```

> `REVERB_APP_SECRET` must remain **server‑side only**.

---

## Running Reverb

Reverb listens on a **local, private port** and should never be exposed directly.

```bash
php artisan reverb:start --host=0.0.0.0 --port=8080
```

In production, this is typically:
- executed inside a Docker container
- supervised via **Supervisor**
- proxied by **Nginx** over HTTPS

---

## TLS setup (Let’s Encrypt + Certbot + Snap)

This project assumes TLS termination is handled by Nginx on the host.

### 1. Prerequisites

- A domain pointing to your server IP
- Open ports: **80** and **443**
- Nginx serving the domain on port 80

### 2. Install Certbot (Snap)

```bash
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
```

### 3. Issue certificate and auto‑configure Nginx

```bash
sudo certbot --nginx \
  -d reverb.your-domain.com \
  -d www.reverb.your-domain.com
```

Certbot will:
- validate domain ownership via HTTP‑01
- download certificates to `/etc/letsencrypt/`
- create an HTTPS (`443`) server block
- configure HTTP → HTTPS redirects
- install automatic renewal via systemd timer

Test renewal:

```bash
sudo certbot renew --dry-run
```

---

## Health checks

Local TCP check (inside host / container):

```bash
nc -z 127.0.0.1 8080
```

or

```bash
php -r "exit(@fsockopen('127.0.0.1', 8080) ? 0 : 1);"
```

HTTPS health endpoint (via Nginx):

```bash
curl https://reverb.your-domain.com/healthz
```

---

## Security notes

- Never expose port **8080** publicly
- Always use **HTTPS / WSS**
- Restrict firewall to ports **22**, **80**, **443**
- WebSocket access requires signed credentials
- Keep Redis/Postgres private

---

## License

MIT License.

Laravel is © Taylor Otwell and contributors.
