#!/bin/bash

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <parquets_dir> <minio_secret_file>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/jhub_data/shared"
SSL_DIR="$SCRIPT_DIR/jhub_data/ssl"
PARQUETS_DIR="$1"
MINIO_SECRET="$2"
MINIO_CREDENTIALS_FILE="$SCRIPT_DIR/jhub_data/.minio_credentials"

echo "Checking shared directory..."
if [ ! -d "$SHARED_DIR" ]; then
    echo "  Creating $SHARED_DIR"
    mkdir -p "$SHARED_DIR"
else
    echo "  OK: $SHARED_DIR"
fi
chown 1000:1000 "$SHARED_DIR"
find "$SHARED_DIR" -maxdepth 1 -mindepth 1 -type d -exec chown 1000:1000 {} \;

echo "Copying MinIO credentials..."
sudo cp "$MINIO_SECRET" "$MINIO_CREDENTIALS_FILE"
sudo chown 1000:1000 "$MINIO_CREDENTIALS_FILE"
sudo chmod 600 "$MINIO_CREDENTIALS_FILE"

echo "Checking SSL certificate..."
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
    echo "  Generating self-signed certificate"
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -days 36500 -newkey rsa:2048 \
        -keyout "$SSL_DIR/server.key" \
        -out "$SSL_DIR/server.crt" \
        -subj "/CN=jupyterhub"
else
    echo "  OK: $SSL_DIR"
fi

echo "Checking parquets directory..."
if [ ! -d "$PARQUETS_DIR" ]; then
    echo "  Creating $PARQUETS_DIR"
    mkdir -p "$PARQUETS_DIR"
else
    echo "  OK: $PARQUETS_DIR"
fi

echo "Writing .env..."
cat > .env <<EOF
SHARED_DIR=$SHARED_DIR
PARQUETS_DIR=$PARQUETS_DIR
MINIO_CREDENTIALS_FILE=$MINIO_CREDENTIALS_FILE
EOF

echo "Building images..."
docker compose build jupyterhub
docker compose build jupyter-user

echo "Starting JupyterHub..."
docker compose up -d

VPN_IP=$(ip -br a 2>/dev/null \
    | grep -v -E '^(lo|en|eth|wl|docker|br-|veth)' \
    | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | head -1)

if [ -n "$VPN_IP" ]; then
    echo "Configuring iptables for VPN local access..."
    sudo iptables -t nat -I OUTPUT -d "$VPN_IP" -p tcp --dport 8000 -j DNAT --to-destination 127.0.0.1:8000
    if command -v netfilter-persistent &>/dev/null; then
        sudo netfilter-persistent save
    else
        sudo apt-get install -y iptables-persistent
        sudo netfilter-persistent save
    fi
    echo "Done. JupyterHub is running at https://$VPN_IP:8000"
else
    echo "Done. JupyterHub is running at https://localhost:8000 (VPN interface not found)"
fi
