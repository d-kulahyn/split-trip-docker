#!/bin/sh
# Run by the nginx image's entrypoint before nginx starts: writes the server
# config, then re-checks it every CONFIG_REFRESH_SECONDS so a certificate
# certbot renewed (or issued for the first time) is served without a restart.
set -eu

split-trip-reload

(
  while sleep "${CONFIG_REFRESH_SECONDS:-21600}"; do
    split-trip-reload --reload || echo "split-trip: config refresh failed, nginx keeps the previous one" >&2
  done
) &
