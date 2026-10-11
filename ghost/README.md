# ghost/

The Docker Compose stack that runs on the VM at `/opt/ghost`.

- `compose.yml`, `caddy/snippets/*`, `mysql-init/*` are vendored unchanged from
  [TryGhost/ghost-docker](https://github.com/TryGhost/ghost-docker) (MIT, Ghost Foundation).
  To pick up upstream changes, diff against that repo and copy the files over.
- `caddy/Caddyfile` is our copy of the upstream example.
- `.env.example` documents every setting. The real `.env` lives in Secret Manager
  (`ghost-env`) and is written to the VM by `scripts/deploy.sh`.

Services that start by default: `caddy`, `ghost`, `db` (MySQL 8).
`analytics` and `activitypub` are behind Compose profiles and off unless `COMPOSE_PROFILES` is set.
