# Accessing the production database

Prod postgres **is reachable over the L2TP VPN** once a route to the host
LAN subnet exists — `psql -h 10.2.16.46 -U ppkobemfk -d ppkobemfk` works
directly (confirmed 2026-07-10). Earlier notes in this doc claimed VPN
couldn't reach `5432` at all ("connection refused") — that was wrong; the
real issue was a missing route (`ppp0` only gets a `/32` route to the VPN
peer, not the `10.2.16.0/24` subnet, so anything beyond the peer showed
"Network is unreachable" until a route was added manually, see §3).

There are three real ways in.

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

## 3. L2TP VPN + direct `psql` (works, but wider blast radius than §2)

Config already exists on this machine (`/etc/ipsec.conf`, `/etc/xl2tpd/`)
pointing at `103.23.102.138`. Bringing it up gets you a `ppp0` interface,
but only a `/32` route to the VPN peer — you need to add a route to the
rest of the LAN subnet before `10.2.16.46` is reachable:

```bash
sudo systemctl restart xl2tpd
sudo xl2tpd-control connect-lac vpn
ip addr show ppp0                        # confirm it's up
sudo ip route add 10.2.16.0/24 dev ppp0  # without this: "Network is unreachable"
PGPASSWORD='...' psql -h 10.2.16.46 -U ppkobemfk -d ppkobemfk
```

Prefer §2 (`docker exec` over SSH) when possible — this path talks straight
to postgres from your machine, no jump host in between, so it's a wider
blast radius (your laptop is now a trusted DB client on shared infra).
Useful mainly when you need a native `psql`/GUI client instead of a shell
session.

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
