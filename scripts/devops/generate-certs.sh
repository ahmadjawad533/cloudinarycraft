#!/usr/bin/env bash
set -e

CERT_DIR="./nginx/certs"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/server.key" ]; then
  echo "Generating self-signed SSL/TLS certificates for local HTTPS testing..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt" \
    -subj "/C=US/ST=State/L=City/O=CloudiCraft/OU=DevOps/CN=localhost"
  echo "Certificates generated in $CERT_DIR"
else
  echo "Certificates already exist in $CERT_DIR"
fi
