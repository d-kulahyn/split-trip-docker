# Production

Two compose files on one server, started in this order:

| File | Runs |
|---|---|
| `docker/docker-compose.prod.yml` | nginx (TLS for `API_DOMAIN`, every request proxied to the API), certbot (renewals), Postgres, Redis. Only nginx publishes ports (80, 443). Networks: `split_trip_edge` (nginx, API, worker — and their way out) and `split_trip_backend` (internal: Postgres, Redis, the application) |
| `nest/docker-compose.prod.yml` | `split_trip_migrate` (`prisma migrate deploy`, then exits), `split_trip_nest` (API + Socket.IO), `split_trip_worker` (outbox relay and handlers) — one image, `nest/docker/node/Dockerfile.prod` |

The dev files (`docker-compose.yml` in both) are not used in production.

## Files on the server (never committed)

| File | From |
|---|---|
| `docker/.env.production` | `docker/.env.production.example` |
| `nest/.env.production` | `nest/.env.production.example` — `DATABASE_URL` is the application's role (`APP_DB_*`), `REDIS_PASSWORD` the value above |
| `nest/.env.production.migrate` | `nest/.env.production.migrate.example` — the schema owner's `DATABASE_URL` (`POSTGRES_*`), the migration step's only secret |
| `/etc/split-trip/firebase.json` (or the path in `FIREBASE_KEY_FILE`) | Firebase console → Project settings → Service accounts → Generate new private key. Outside the repository; readable by uid 1000 (`chown 1000 … && chmod 0400 …`). It must exist before the worker starts: a missing file makes Docker mount an empty directory and the worker fails to boot |

Postgres creates the application's role (`APP_DB_USER`, read and write on the
tables, no superuser) when its volume is first initialised
(`pg/prod-init/10-app-role.sh`). Changing that user or password later is an
`ALTER ROLE` by hand.

## First deploy

1. DNS: an A record for `API_DOMAIN` pointing at the server; ports 80 and 443 open.
2. Infrastructure:
   ```bash
   cd docker
   docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
   ```
   nginx starts without a certificate and serves only the ACME challenge (its log says so).
3. The first certificate:
   ```bash
   docker compose -f docker-compose.prod.yml --env-file .env.production run --rm \
     --entrypoint certbot split_trip_certbot certonly --webroot -w /var/www/certbot \
     -d way-pay.org --email <operator address> --agree-tos --no-eff-email
   docker exec split_trip_web split-trip-reload --reload
   ```
   From then on certbot renews on its own and nginx picks a renewed certificate up within 6 hours (`CONFIG_REFRESH_SECONDS`).
4. The application:
   ```bash
   cd ../nest
   docker compose -f docker-compose.prod.yml up -d --build
   ```
   The migration runs first; the API and the worker start only if it succeeds.
5. Check:
   ```bash
   curl -sI https://way-pay.org/api/currencies/codes          # 200
   curl -s  https://way-pay.org/.well-known/assetlinks.json   # the Play App Signing SHA-256
   docker compose -f docker-compose.prod.yml exec split_trip_worker npm run console:prod -- outbox:status
   ```

## Updating

```bash
cd nest && git pull && docker compose -f docker-compose.prod.yml up -d --build
```

Before a release whose notes ask for a drain (`.claude/rules/migration-status.md` § Operator steps), stop the API first and wait for `outbox:status --require-drained` to exit 0.

## Operator commands

`npm run console` runs TypeScript and exists only in the dev image. In production:

```bash
docker compose -f docker-compose.prod.yml exec split_trip_worker npm run console:prod -- <command>
```

## Data

| What | Where |
|---|---|
| Postgres | volume `pg_data` (infrastructure project) |
| Redis (BullMQ jobs, append-only file) | volume `redis_data` |
| Certificates | volume `letsencrypt` |
| Uploaded avatars | volume `avatars` (application project) |

Back up `pg_data` and `avatars`; the rest can be recreated.
