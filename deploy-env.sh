#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "❌ Failed at line $LINENO. Command: $BASH_COMMAND" >&2' ERR

export DEBIAN_FRONTEND=noninteractive

# deny !root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root (sudo ./setup.sh)" >&2
  exit 1
fi


# ---------- Update packages ----------
apt-get update
apt-get upgrade -y


# ---------- Base deps ----------
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release \
  git ufw \
  unzip


# ---------- Install Docker from official repo ----------
install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"


cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update
apt-get install -y --no-install-recommends \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# Add a real user (not root) to docker group
TARGET_USER="${SUDO_USER:-}"
if [[ -n "$TARGET_USER" ]]; then
  usermod -aG docker "$TARGET_USER"
  echo "ℹ️ Added $TARGET_USER to docker group (log out/in to apply)."
else
  echo "ℹ️ Not adding to docker group (no SUDO_USER detected)."
fi


# ---------- Install Nginx ----------
apt-get install -y --no-install-recommends nginx
systemctl enable --now nginx


# ---------- Setup Reverb Htpasswd ----------
ENV_FILE=".env"
HTPASSWD_FILE="/etc/nginx/.reverb_htpasswd"

echo "🔎 Reading credentials from ${ENV_FILE}..."

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found"
  exit 1
fi

REVERB_USER=$(grep -E '^REVERB_AUTH_BASE_USER=' "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
REVERB_PASS=$(grep -E '^REVERB_AUTH_BASE_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'")

if [ -z "${REVERB_USER:-}" ] || [ -z "${REVERB_PASS:-}" ]; then
  echo "❌ Missing REVERB_AUTH_BASE_USER or REVERB_AUTH_BASE_PASSWORD in .env"
  exit 1
fi

echo "👤 User: $REVERB_USER"
echo "🔐 Generating bcrypt htpasswd file..."

# apache2-utils
if ! command -v htpasswd >/dev/null 2>&1; then
  echo "📦 Installing apache2-utils..."
  apt install -y apache2-utils
fi

# create/update htpasswd file
htpasswd -bBc "$HTPASSWD_FILE" "$REVERB_USER" "$REVERB_PASS"

echo "🔒 Setting secure permissions..."
chmod 640 "$HTPASSWD_FILE"

echo "✅ Reverb Basic Auth configured successfully."


# ---------- Firewall ----------
# reset any existing rules so reruns are deterministic
ufw --force reset
# default deny everything incoming; allow all outgoing
ufw default deny incoming
ufw default allow outgoing
# allow ssh/http(s)
ufw allow OpenSSH
ufw allow 'Nginx Full'
# enable firewall
ufw --force enable


# ---------- misc. settings ----------
sysctl -w vm.overcommit_memory=1
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf


# ---------- Debug ----------
echo -e "\n=== Setup complete ==="
echo "Git: $(git --version)"
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "Nginx: $(nginx -v 2>&1)"
echo "UFW: $(ufw status | head -n 1)"
