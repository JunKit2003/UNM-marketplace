# Nott-A-Marketplace

**Buy, sell and swap on campus.** A marketplace for the University of Nottingham Malaysia community, first built as a 2024 Software Engineering group project and rebuilt end to end in 2026.

**Live demo: [unm.junkit.my](https://unm.junkit.my)** · press **Try the demo** for a guest account. No sign-up needed, and visitor data resets every night.

![Browse page](docs/screenshots/browse-desktop.png)

<p>
  <img src="docs/screenshots/listing-desktop.png" width="49%" alt="Listing page">
  <img src="docs/screenshots/chat-desktop.png" width="49%" alt="Live chat">
</p>
<p>
  <img src="docs/screenshots/browse-phone.png" width="24%" alt="Browse on a phone">
  <img src="docs/screenshots/sell-phone.png" width="24%" alt="Sell flow on a phone">
  <img src="docs/screenshots/chat-phone.png" width="24%" alt="Chat on a phone">
  <img src="docs/screenshots/login-phone.png" width="24%" alt="Login on a phone">
</p>

## Features

- **Browse:** full-text search, category chips with live counts, condition and price filters, sorting, a masonry grid with infinite scroll. Every filter lives in the URL, so a view can be shared.
- **Listings:** swipeable, keyboard-driven gallery with fullscreen zoom, a shareable link per listing, save with a heart.
- **Sell:** a three-step flow (photos with drag-and-drop and reordering, details, review) with a live preview. Owners can edit, mark as sold or delete.
- **Live chat:** built in (Socket.IO + MySQL), with typing dots, read receipts, unread badges and optimistic sending with retry.
- **Showcase mode:** one-click guest accounts that start with a saved listing and a waiting chat, demo sellers who reply, and a nightly reset at 03:00 MYT.
- **Dark-first design:** a "Campus at night" theme with a light mode, frosted glass, an animated gradient hero and shared-element photo transitions. It works from a 360 px phone up to a wide desktop.

## Stack

| Part | Tech |
|---|---|
| Frontend | Flutter 3 (web), Dart 3, Riverpod, go_router, socket_io_client |
| API | Node 24, Express 5, mysql2, express-session (MySQL store), zod, sharp, Socket.IO |
| Database | MySQL 8.4 with SQL migrations |
| Serving | nginx container (serves the app and proxies `/api`, `/images`, `/socket.io`) |
| Delivery | Docker Compose, GitHub Actions → GHCR → SSH deploy with automatic rollback |
| Tests | Vitest + Supertest against MySQL (API), flutter_test widget tests (web), an nginx routing check |

## Run it locally

You need Docker.

```bash
cp .env.example .env
docker compose up -d --build
```

Open <http://localhost:8080>. If port 8080 is taken, set `WEB_PORT=8088` (or similar) in `.env`. The first start seeds the demo data. Adminer (database UI) is available with `docker compose --profile dev up -d adminer` at <http://localhost:8081>.

Behind a network that inspects TLS (a corporate proxy), point `NPM_CA_FILE` in `.env` at your CA bundle, e.g. `/etc/ssl/certs/ca-certificates.crt`, so the image builds can download packages.

## Tests

```bash
# API (needs the db container: docker compose up -d db)
cd src/server && npm ci && npm run lint && npm test

# Web (Flutter installed locally, or use the ghcr.io/cirruslabs/flutter image)
cd src/unm_marketplace && flutter pub get && flutter analyze && flutter test

# nginx routing, against the built web image
IMAGE=unm-marketplace-web bash src/unm_marketplace/nginx/test.sh
```

## Deploying

Every push to `main` runs the checks, publishes the images and deploys to the VPS. A release that fails its health check is rolled back automatically. The one-time server setup, secrets and rollback steps are in [docs/deploy-handoff.md](docs/deploy-handoff.md).

## Project layout

```
compose.yaml / compose.prod.yaml   local and production stacks
src/server/                        Express API, migrations, demo seed, tests
src/unm_marketplace/               Flutter app, nginx config for the web image
deploy/                            VPS deploy script and host nginx example
docs/                              design doc, acceptance spec, plan, deploy handoff
```

## Credits

Built by [Jun Kit](https://junkit.my). The original 2024 version was a University of Nottingham Malaysia Software Engineering group project; that code is kept on the [`from-uni`](https://github.com/JunKit2003/UNM-marketplace/tree/from-uni) branch. Demo photos are openly licensed and credited in [src/server/src/seed/CREDITS.md](src/server/src/seed/CREDITS.md).
