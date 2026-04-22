#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <lakefs_secret_file>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/jhub_data/shared"
SSL_DIR="$SCRIPT_DIR/jhub_data/ssl"
LAKEFS_SECRET="$1"
LAKEFS_CREDENTIALS_FILE="$SCRIPT_DIR/jhub_data/.lakefs_credentials"

JHUB_DATA_DIR="$SCRIPT_DIR/jhub_data"
if [ -d "$JHUB_DATA_DIR" ] && [ ! -w "$JHUB_DATA_DIR" ]; then
    echo "Fixing jhub_data ownership..."
    sudo chown "$USER:$USER" "$JHUB_DATA_DIR"
fi

echo "Checking shared directory..."
if [ ! -d "$SHARED_DIR" ]; then
    echo "  Creating $SHARED_DIR"
    mkdir -p "$SHARED_DIR"
else
    echo "  OK: $SHARED_DIR"
fi
chown 1000:1000 "$SHARED_DIR"
find "$SHARED_DIR" -maxdepth 1 -mindepth 1 -type d -exec chown 1000:1000 {} \;

echo "Copying lakeFS credentials..."
sudo cp "$LAKEFS_SECRET" "$LAKEFS_CREDENTIALS_FILE"
sudo chown 1000:1000 "$LAKEFS_CREDENTIALS_FILE"
sudo chmod 600 "$LAKEFS_CREDENTIALS_FILE"

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

echo "Writing .env..."
cat > .env <<EOF
SHARED_DIR=$SHARED_DIR
LAKEFS_CREDENTIALS_FILE=$LAKEFS_CREDENTIALS_FILE
EOF

echo "Building images..."
docker compose build jupyterhub
docker compose build jupyter-user

echo "Starting JupyterHub..."
docker compose up -d

echo "Done. JupyterHub is running at https://localhost:8000"
