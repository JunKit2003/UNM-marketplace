# UNM Marketplace revamp: containers, redesign, own chat, CI/CD design

Acceptance spec: [docs/revamp-containers-spec.md](../revamp-containers-spec.md)

## 1. Summary & goal

The 2024 group project went offline. This revives it at `unm.junkit.my` as a **showcase piece for the Portfolio website**: something a recruiter can open, click "Try the demo", and see a polished, working marketplace in under a minute. It uses the same container stack as the Faction Bikeworks revamp (`Final-Year-Project`, branch `feature/revamp-containers`).

- **Containerise** everything: `web` (nginx serving the Flutter web build, proxying `/api`, `/images`, `/socket.io`), `api` (Node), `db` (MySQL 8). One `docker compose up` runs the whole site locally.
- **Rebuild the backend** on current packages (Express 5, `mysql2` pool, ESM) with a REST API, server-side identity, validation, and sessions that survive restarts.
- **Replace Stream chat** with our own chat in the Node backend (Socket.IO, messages stored in MySQL).
- **Redesign the Flutter frontend** end to end on Dart 3 / current Flutter stable.
- **Ship a CI/CD pipeline**: every push to `main` is checked, and if green, the new images go live on the VM automatically (frontend and backend).

### Answers to the open questions
- *Portfolio or real use?* Portfolio showcase. So: rich demo data is always present, one-click demo login, a demo seller who replies in chat, and a nightly reset so strangers can't leave it messy. It is still public, so the security basics stay.
- *Keep Stream?* No. Its secret key is committed in a public repo, it needs a third-party account, and the free tier can change. Own chat removes all of that.
- *Backend deploy manual like ConsignCars?* No, the pipeline deploys both.

## 2. Scope

**In scope**
- Dockerfiles for `web` and `api`, `compose.yaml` for local dev (+ Adminer on a `dev` profile), `compose.prod.yaml` for the VM.
- Backend rewrite of all 23 existing endpoints as REST routes, plus chat.
- **Showcase extras:** ~30 demo listings with real photos across all categories, 3 demo personas, "Try the demo" one-click login, an auto-replying demo seller, nightly demo reset, and an "About this project" page linking back to the Portfolio.
- New MySQL schema with migrations and a seed (categories, optional demo data).
- Full Flutter UI rewrite: browse, listing detail, sell / edit, my listings, saved, messages, profile, auth.
- GitHub Actions: lint, test, build, push images to GHCR, deploy over SSH, rollback by image tag.
- `docs/deploy-handoff.md`: what the VPS needs (Docker, a `.env`, host nginx site for `unm.junkit.my` → `web`, TLS, GitHub secrets), written for the agent that manages the VPS.

**Out of scope**
- Native Android / iOS releases (the code keeps compiling for them; only web is built, tested and deployed).
- Payments, reviews/ratings, admin moderation console, email verification, push notifications.
- Migrating the old 2024 data (2 test listings whose images are not in the repo).
- **VPS setup**: DNS, host nginx, TLS certificate, port allocation and secrets are done by the separate VPS agent from the handoff doc. `web` binds to `WEB_BIND` (default `127.0.0.1:8090`) so the port can be changed without code changes.

**Definition of Done**
- `docker compose up` on a clean machine serves a working site on `http://localhost:8080`, already full of demo listings.
- All acceptance scenarios in the spec hold on that local stack.
- CI is green on the PR; the deploy job is in place and works once the VPS agent has done the handoff steps (not verified in this delivery).

## 3. Architecture & data ownership

```
browser ── https ──> host nginx (VM, TLS) ──> web:80 (nginx + Flutter build)
                                               ├─ /api/*, /images/*, /socket.io/*  ──> api:3000 (Express 5 + Socket.IO)
                                               └─ everything else ──> Flutter index.html
api ──> db:3306 (MySQL 8, volume db-data);  uploads on volume uploads (/app/uploads, served as /images)
```

One origin everywhere, so no CORS configuration and the session cookie is first-party (`HttpOnly`, `SameSite=Lax`, `Secure` in prod).

### Who owns what
| Thing | Owner | Notes |
|---|---|---|
| Users, sessions | `api` / MySQL `users`, `sessions` | bcrypt hashes; sessions via `express-mysql-session` |
| Listings, photos | `api` / `listings`, `listing_images`, volume `uploads` | up to 6 photos, first = cover |
| Saved listings | `api` / `saved_listings` | unique (user, listing) |
| Chat | `api` / `conversations`, `messages` | one conversation per (listing, buyer); seller is the listing owner |
| UI state | Flutter (Riverpod) | nothing authoritative client-side |

### The rules that fall out of this
- **The server decides who you are.** Every write uses `req.session.userId`; usernames/IDs sent in the body are ignored. (Today any client can post or save as anyone.)
- **Only owners change listings.** Edit / delete / photo routes return 403 for anyone else.
- **Only participants see a conversation.** Socket joins are checked against the DB.
- **Uploads are checked**: JPEG / PNG / WebP only, 5 MB each, random filenames, re-encoded with `sharp` to strip metadata.
- **Secrets live in `.env`** on the VM and in GitHub secrets, never in code.

### Endpoints (all under `/api`, JSON, validated with `zod`)
| Method & path | Purpose |
|---|---|
| `POST /auth/signup`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/me` | account + session (login rate-limited) |
| `PATCH /me`, `PUT /me/password`, `PUT /me/photo` | profile |
| `GET /categories` | category list with counts |
| `GET /listings?q=&category=&condition=&min=&max=&sort=&page=` | browse (paged, 24/page) |
| `GET /listings/:id`, `POST /listings`, `PATCH /listings/:id`, `DELETE /listings/:id` | listing CRUD |
| `POST /listings/:id/images`, `DELETE /listings/:id/images/:imageId` | photos |
| `GET /me/listings`, `GET /me/saved`, `PUT /listings/:id/save`, `DELETE /listings/:id/save` | mine / saved |
| `GET /conversations`, `POST /listings/:id/conversations`, `GET /conversations/:id/messages?before=` | chat history |
| Socket.IO `message:send`, `message:new`, `typing`, `conversation:read` | live chat (session-authenticated) |
| `GET /health` | container healthcheck |

### Changes to existing endpoints
| Old | New |
|---|---|
| 23 `POST /api/<Verb>` routes, reads included | REST routes above; old routes removed (only this frontend uses them) |
| `createStreamUserAndToken`, `getStreamToken` | removed; replaced by own chat |
| `authenticate`, `getUsername`, `profile` | merged into `GET /auth/me` |

Migrations: plain SQL files in `server/migrations/NNN_*.sql`, applied on startup by a small runner that tracks a `schema_migrations` table. First file `001_init.sql`; `seed.js` adds categories and the demo data (`SEED_DEMO=true`, the default, also on the VM).

### Demo mode (showcase)
- **Personas:** `wei.jie`, `priya` and `aisyah` own the seeded listings and are flagged `is_seed`. Nobody can log in as them.
- **Try the demo (builder call):** `POST /api/auth/demo` creates a fresh guest buyer per click ("Guest 4821", `is_guest`), with one seeded saved listing and one seeded chat thread, so every visitor starts clean and never sees another visitor's activity. Guests can do everything a student can (sell, save, chat, edit profile) except set a password or delete the account. Limit: 10 guest accounts per IP per hour.
- **Demo seller replies:** when someone messages a demo seller, the api answers after ~1.5 s with a typing indicator first, picking from a small set of friendly, listing-aware replies ("Hi! Yes, the <title> is still available."). This lets a single visitor see live chat working.
- **Nightly reset (03:00 MYT):** an in-process job (`node-cron`) removes all non-seed data (guest and signed-up accounts, their listings and photos, all messages, sessions) and re-applies the seed. A banner says "Demo site. Data resets nightly."
- **Photos (builder call):** the builder picks ~30 Unsplash-licence photos and writes the titles, prices and descriptions (UNM-flavoured: textbooks, desk lamps, a bicycle, a rice cooker…). They're committed under `server/seed/images/` as 1600 px WebP with credits in `server/seed/CREDITS.md`, so builds and CI never need the internet.
- **Abuse limits:** per-IP limits on signup (5/h), listing creation (20/day), uploads and messages (60/min).

### Stack versions (latest stable at build time, pinned in lockfiles / Dockerfiles)
- **api:** Node 24 LTS, Express 5, mysql2, express-session + express-mysql-session, bcrypt, multer 2, sharp, zod, helmet, express-rate-limit, socket.io, node-cron, pino. Tests: Vitest + Supertest against a MySQL service.
- **web:** Flutter stable (image `ghcr.io/cirruslabs/flutter`), go_router, flutter_riverpod, dio, socket_io_client, cached_network_image, google_fonts, flutter_animate. Served by `nginx:alpine`.

### CI/CD (`.github/workflows/ci-deploy.yml`)
1. **check** (PRs + `main`): api lint + tests (MySQL service container); `flutter analyze` + `flutter test`; both Docker builds.
2. **publish** (`main` only): push `ghcr.io/junkit2003/unm-marketplace-{web,api}:<sha>` and `:latest`. Packages are **public** (builder call: the repo is public anyway), so the VM pulls without a login.
3. **deploy**: SSH to the VM (`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PORT`, same names as ConsignCars), `IMAGE_TAG=<sha> docker compose -f compose.prod.yaml pull && up -d`, then poll `/api/health`. On failure it redeploys the previous tag automatically. Manual rollback = rerun with an older tag (`workflow_dispatch` input).

## 4. Product-visible behaviour & copy

**Name:** "Nott-A-Marketplace". Tagline: "Buy, sell and swap on campus."

**Look ("Campus at night"):** a dark-first theme with a light mode toggle. Deep ink background `#0B1020`, UNM navy `#10263B` surfaces, an electric-violet → cyan gradient accent, frosted-glass panels, Space Grotesk headings and Inter body text. Motion: a parallax gradient-mesh hero, staggered card fade-ins, shared-element (Hero) photo transition from card to detail, skeleton shimmer while loading, springy save heart, and live typing dots in chat. Responsive: bottom nav on phones, side rail on tablets / desktop.

**Showcase touches:** a "Try the demo" button on the hero and on the login screen; a slim top banner "Demo site. Data resets nightly. Built by Jun Kit ↗" (links to the Portfolio); an **About** page with the stack, architecture diagram, what was rebuilt in 2026 vs the 2024 original, and links to GitHub and the Portfolio.

**Screens**
- **Browse (home):** hero with search ("What are you looking for?"), category chips with icons, sort (Newest, Price low→high, Price high→low), filter sheet (condition, price range), masonry grid of cards (cover photo, price `RM 1,234`, title, condition pill, "2h ago"), infinite scroll. Empty: "Nothing here yet. Be the first to sell something."
- **Listing detail:** swipeable gallery with fullscreen view, price, condition, category, description, seller card, "Message seller", "Save", share link (`/listing/:id`). Owner sees "Edit" and "Mark as sold" / "Delete" instead.
- **Sell / Edit:** three steps (Photos → Details → Review), drag-and-drop photos, live preview card. Success: "Your listing is live."
- **Messages:** inbox with unread badges and listing thumbnails; thread view with bubbles, timestamps, typing indicator, "Seen".
- **Profile:** photo, name, my listings, saved, change password, log out.
- **Auth:** one screen with Log in / Sign up tabs. Errors: "Email or password is wrong.", "That email is already registered."

## 5. Known limitations
- Single VM, single `api` instance (Socket.IO has no Redis adapter; fine at campus scale).
- No email verification; anyone can sign up. Everything non-seed is wiped nightly, so nothing is kept long term.
- **The Stream API secret in git history stays exposed.** Delete that Stream app from the Stream dashboard; rewriting history is not planned.
- Old 2024 listings are not migrated.
