# Production reverse proxy: terminates TLS for API_DOMAIN and passes every
# request to the Nest API. Certificates come from the certbot service through
# the shared `letsencrypt` volume (`../../docker-compose.prod.yml`).
FROM nginx:1.27.3-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY snippets/ /etc/nginx/snippets/
COPY templates/ /etc/nginx/split-trip/
COPY split-trip-reload.sh /usr/local/bin/split-trip-reload
COPY 40-split-trip-config.sh /docker-entrypoint.d/40-split-trip-config.sh

RUN chmod +x /usr/local/bin/split-trip-reload /docker-entrypoint.d/40-split-trip-config.sh \
    && rm -f /etc/nginx/conf.d/default.conf
