# Deploy handoff: unm.junkit.my

For whoever (or whichever agent) manages the VPS. The app ships as two images on GHCR plus MySQL, all run by `compose.prod.yaml`. CI does every deploy after this one-time setup.

```
browser ─https─> host nginx (TLS, this VPS) ─> 127.0.0.1:8090 web (nginx + Flutter) ─> api (Node) ─> db (MySQL)
```

## 1. One-time VPS setup

1. **DNS:** `unm.junkit.my` A/AAAA record → the VPS.
2. **Docker** with the Compose plugin, plus `curl`. The deploy user must be able to run `docker` (in the `docker` group).
3. **Deploy folder** (default `~/apps/unm-marketplace`; change it with the `DEPLOY_PATH` repo variable):
   ```bash
   mkdir -p ~/apps/unm-marketplace && cd ~/apps/unm-marketplace
   ```
4. **`.env`** in that folder (never committed):
   ```bash
   DB_PASSWORD=<random>
   DB_ROOT_PASSWORD=<random>
   SESSION_SECRET=<openssl rand -hex 32>
   TRUST_PROXY=2               # host nginx + web nginx
   SEED_DEMO=true              # showcase mode: demo data, guest login, nightly reset
   WEB_BIND=127.0.0.1:8090     # pick any free local port; the host nginx points here
   ```
   `TRUST_PROXY=2` matters: with fewer hops every visitor shares one IP and the login rate limit locks everyone out.
5. **Host nginx + TLS:** copy `deploy/nginx/host-unm.junkit.my.conf` into the nginx sites folder, adjust the port if `WEB_BIND` differs, get a certificate (for example `certbot --nginx -d unm.junkit.my`), then `nginx -t && systemctl reload nginx`. WebSocket upgrade headers and `client_max_body_size 40m` are required (live chat and photo uploads).

## 2. GitHub settings (repo → Settings)

| Kind | Name | Value |
|---|---|---|
| Secret | `DEPLOY_HOST` | VPS hostname or IP |
| Secret | `DEPLOY_USER` | SSH user that runs Docker |
| Secret | `DEPLOY_SSH_KEY` | private key for that user (its public key in `~/.ssh/authorized_keys`) |
| Secret | `DEPLOY_KNOWN_HOSTS` | Verified SSH host keys for the VPS |
| Secret | `DEPLOY_PORT` | SSH port, if not 22 |
| Variable | `DEPLOY_PATH` | only if not `~/apps/unm-marketplace` |
| Environment | `production` | created automatically on the first run; add protection rules if wanted |

Same secret names as ConsignCars. Until they're set, the deploy job passes with a warning and deploys nothing.

**Packages:** CI builds for the ARM64 VPS and uses its job token to pull the GHCR images during deployment.

## 3. How a deploy works

Every push to `main`: API lint + tests (against MySQL), Flutter analyze + tests, both images built, nginx routing checked, images pushed as `:<commit sha>` and `:latest`, then CI copies `compose.prod.yaml` and `deploy/remote-deploy.sh` to the VPS and runs:

```bash
bash ~/apps/unm-marketplace/remote-deploy.sh <commit sha>
```

The script pulls that tag, restarts the stack and polls `http://$WEB_BIND/api/health` for 90 s. Healthy → the tag is saved in `.current_tag`. Unhealthy → it redeploys the previous tag and the CI run goes red.

## 4. Rollback

- **From GitHub:** Actions → *CI / Deploy* → *Run workflow* on `main` with `image_tag` = an older commit SHA. It skips the build and deploys that tag.
- **On the VPS:** `cd ~/apps/unm-marketplace && bash remote-deploy.sh <older sha>`.

## 5. Day-to-day

| Task | Command (in the deploy folder) |
|---|---|
| Status | `docker compose -f compose.prod.yaml ps` |
| Logs | `docker compose -f compose.prod.yaml logs -f api` |
| Reset the demo now | `docker compose -f compose.prod.yaml exec api node src/seed/reset-cli.js` |
| MySQL shell | `docker compose -f compose.prod.yaml exec db mysql -uunm -p unm` |
| Wipe everything | `docker compose -f compose.prod.yaml down -v` (deletes the database and photos) |

The demo also resets itself every night at 03:00 Malaysia time.

## 6. Checks after the first deploy

- `curl -s https://unm.junkit.my/api/health` → `{"ok":true}`
- The home page shows the demo listings, and "Try the demo" logs in.
- Messaging a demo seller shows typing dots, then a reply (this proves WebSockets pass through the host nginx).
- Response headers on `/api/auth/demo` include `Set-Cookie: unm.sid=…; Secure` (proves `X-Forwarded-Proto` and `TRUST_PROXY` are right).
