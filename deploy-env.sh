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

# ---------- Git config (root only) ----------
# git config --global user.name "nikolav"
# git config --global user.email "admin@nikolav.rs"

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

# autoload @/etc/nginx/conf.d/*.conf
tee /etc/nginx/conf.d/00-connection-upgrade.conf > /dev/null <<'EOF'
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}
EOF

# autoload @/etc/nginx/conf.d/*.conf
tee /etc/nginx/conf.d/01-origin-allowed.conf > /dev/null <<'EOF'
map $http_origin $origin_allowed {
  default 0;
  "https://nikolav.rs" 1;
  "http://localhost:3000" 1;

  # allow no origin (curl, internal services)
  "" 1;
}
EOF

# # ---------- Install Node (local testing, wscat) ----------
# # prerequisites
# apt update
# apt install -y curl ca-certificates
# # nvm
# curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# source ~/.bashrc
# nvm install --lts
# nvm use --lts
# # wscat (sanity checks ws)
# npm i -g wscat

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
# echo "Node/npm: $(node -v) $(npm -v)"
