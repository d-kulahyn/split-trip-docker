#!/bin/sh
# Writes the server config for API_DOMAIN — TLS once its certificate exists,
# the ACME challenge alone before — and, with `--reload`, reloads nginx so a
# renewed or first-issued certificate is picked up.
set -eu

: "${API_DOMAIN:?API_DOMAIN is required}"

CERTIFICATE="/etc/letsencrypt/live/${API_DOMAIN}/fullchain.pem"
TEMPLATES=/etc/nginx/split-trip
TARGET=/etc/nginx/conf.d/default.conf

if [ -f "$CERTIFICATE" ]; then
  template=tls
else
  template=acme-only
  echo "split-trip: no certificate for ${API_DOMAIN} yet, serving the ACME challenge only" >&2
fi

envsubst '${API_DOMAIN}' < "${TEMPLATES}/${template}.conf.template" > "$TARGET"

if [ "${1:-}" = "--reload" ]; then
  nginx -t -q
  nginx -s reload
fi
