# Accessing the production database

Prod postgres has **no exposed port** — `docker-compose.prod.yml`'s `postgres`
service has no `ports:` mapping, so it's only reachable inside the docker
network by the `backend` container. Neither the public internet nor the
office L2TP VPN can reach `5432` directly (confirmed: VPN gets you onto the
host LAN, `psql -h 10.2.16.46` still gets "connection refused").

There are two real ways in.

## 1. Through the app API (preferred)

Almost everything — reading users/profiles, creating/resetting accounts,
checking health — is reachable through the public API without touching the
DB at all:

```
https://mediku.appunnes.id/api/v1
```

Login as SUPERADMIN for admin-level reads/writes (`/admin/users`,
`/admin/patients`), or as a specific account to see what that account sees.
Use this whenever the question can be answered by "what does the app show."

## 2. `docker exec` over SSH (for raw DB queries)

For anything the API can't answer (schema inspection, ad-hoc SQL, checking
row counts), SSH in and exec into the postgres container directly — same
container network the backend uses, no tunnel needed.

**Path**: your machine → SSH → `103.23.102.190` (jump/deploy host) → SSH →
`10.2.16.46` (internal host running the docker containers) → `docker exec`
into the postgres container.

```bash
ssh admin@103.23.102.190 "ssh admin@10.2.16.46 \"docker exec -it fk_medikuappunnesid_bem-postgres-1 psql -U \$POSTGRES_USER -d \$POSTGRES_DB\""
```

(Confirm the exact postgres container name with
`docker ps --format '{{.Names}}'` on `10.2.16.46` first — containers are
named by the ansible/compose project prefix, e.g.
`fk_medikuappunnesid_bem-backend-1` for the app; postgres follows the same
`fk_medikuappunnesid_bem-*` pattern.)

Requires: the GitHub Actions deploy SSH key (or an equivalent key with
access to `admin@103.23.102.190`).

## 3. L2TP VPN (does NOT reach postgres — documented for completeness)

Config already exists on this machine (`/etc/ipsec.conf`, `/etc/xl2tpd/`)
pointing at `103.23.102.138`. Bringing it up gets you a `ppp0` interface on
the `10.2.16.x` LAN, which is useful for reaching other internal-only
services on that network — but **not** postgres, since it isn't listening
on the host's IP at all (see above). Don't use this path for DB access;
listed here only so it isn't rediscovered as a dead end again.

```bash
sudo systemctl restart xl2tpd
sudo xl2tpd-control connect-lac vpn
ip addr show ppp0   # confirm it's up
```

## Credentials

Not stored in this file or anywhere in the repo — private repo or not,
plaintext prod credentials shouldn't live in git history. Get current
SSH key / VPN credentials / DB password from whoever manages
`103.23.102.190` / the L2TP VPN.

## Notes

- Prod DB and internal hosts are shared infra with ~19 other faculty apps
  on the same droplet — treat any direct DB session as read-only unless a
  write is specifically intended, and prefer the API path (§1) whenever
  it can answer the question.
- Always prefer the smallest-blast-radius option that answers the
  question: API > docker exec over SSH > nothing else. Don't reach for
  raw DB/VPN access as a default.
