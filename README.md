# Laravel Reverb WebSocket Server

Minimal, production‑ready **Laravel Reverb** WebSocket service designed to run as shared infrastructure behind **Nginx + TLS (WSS)**.

This is **not a web app**. It runs Reverb as a long‑lived background service and exposes it securely over HTTPS.

---

## What this is

- Standalone **Laravel Reverb** server (Pusher‑compatible)
- Shared realtime backend for one or more Laravel apps
- Intended for Docker / Supervisor deployments
- Public access **only via HTTPS / WSS**

---

## Basic architecture

```text
Clients
  |
  |  wss://reverb.your-domain.com
  v
Nginx (TLS)
  |
  |  http://127.0.0.1:8080
  v
Laravel Reverb
```

---

## Quick start

```bash
cp .env.example .env
php artisan key:generate
```

Minimal Reverb config:

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=1
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret

REVERB_HOST=reverb.your-domain.com
REVERB_PORT=443
REVERB_SCHEME=https
```

Run Reverb on a **private port**:

```bash
php artisan reverb:start --host=0.0.0.0 --port=8080
```

> Never expose port `8080` publicly.

---

## TLS setup (Certbot + Nginx)

### 1. Requirements

- Domain pointing to your server
- Ports **80** and **443** open
- Nginx serving the domain on port 80

### 2. Install Certbot (Snap)

```bash
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
```

### 3. Issue certificate

```bash
sudo certbot --nginx -d reverb.your-domain.com
```

Certbot will:
- generate certificates in `/etc/letsencrypt`
- create HTTPS (`443`) config
- redirect HTTP → HTTPS
- enable auto‑renewal

Test renewal:

```bash
sudo certbot renew --dry-run
```

---

## Security notes

- Use **HTTPS / WSS only**
- Firewall: allow **22**, **80**, **443**
- Keep Redis / DB private
- `REVERB_APP_SECRET` must stay server‑side

---

## License

MIT
