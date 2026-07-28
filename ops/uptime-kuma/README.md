# Uptime Kuma

Monitors the mediku backend. Runs on the CI/CD host `103.23.102.190`, not on the
app host `10.2.16.46` — a dead app host must still be able to raise an alert.

Monitors (seeded by `deploy.yml`, keyed on URL so re-runs never duplicate):

| Monitor | URL |
|---|---|
| Mediku Backend (internal) | `http://10.2.16.46:39024/api/v1/health` |
| Mediku Public | `https://mediku.appunnes.id/api/v1/health` |

Both hit the DB-checked health route, which returns 503 when Prisma loses the
database. Public down + internal up means the `103.23.102.191` gateway is the problem.

## Access

`https://kuma.<your-tailnet>.ts.net` — from any device signed into the tailnet.

`.190` accepts only ports 22 and 80 inbound and its nginx is root-owned with no
sudo available, so tailscale's outbound-only connection is what makes this work.
Fallback if tailscale is down:

```bash
ssh -L 3001:localhost:3001 admin@103.23.102.190   # then http://localhost:3001
```

## First-time setup

1. In the Tailscale admin console, enable **MagicDNS** and **HTTPS Certificates**
   (DNS tab). Without both, the `.ts.net` URL gets no cert.
2. Generate an auth key (Settings → Keys). Single-use is enough — it is consumed
   at first connect, and `./ts-state` keeps the node authenticated afterwards.
3. Write it on `.190`, never into git:

   ```bash
   ssh admin@103.23.102.190 'umask 077; echo "TS_AUTHKEY=tskey-auth-..." > /home/admin/uptime-kuma/.env'
   ```
4. Deploy: push to `production`, or run it directly on `.190`:

   ```bash
   cd /home/admin/ppko_bem_fk && ansible-playbook -i localhost, ops/uptime-kuma/deploy.yml
   ```
5. Open the URL and complete Kuma's setup wizard — it creates the admin account
   (`user_id 1`, which the seeded monitors are already assigned to).
6. Add a notification channel in the UI. Until then this is a dashboard, not an
   alarm: nothing pages you when the backend drops.
