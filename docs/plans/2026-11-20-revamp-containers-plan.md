# UNM Marketplace revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revive the 2024 UNM Marketplace as a containerised, redesigned portfolio showcase with its own chat and a CI/CD pipeline.

**Architecture:** Three containers (`web` = nginx + Flutter web build, `api` = Node 24 / Express 5 / Socket.IO, `db` = MySQL 8.4). nginx serves one origin and proxies `/api`, `/images`, `/socket.io` to `api`. GitHub Actions checks, publishes images to GHCR and deploys over SSH.

**Tech Stack:** Node 24, Express 5, mysql2, express-session + express-mysql-session, bcrypt, multer 2, sharp, zod, helmet, express-rate-limit, socket.io, node-cron, pino, Vitest + Supertest, ESLint 10; Flutter stable (Dart 3), go_router, flutter_riverpod, dio, socket_io_client, cached_network_image, flutter_animate; nginx:alpine; GitHub Actions.

**Spec:** `docs/plans/2026-11-20-revamp-containers-design.md` and `docs/revamp-containers-spec.md` (RV-01 … RV-08).

## Global Constraints

- Paths stay `src/server` (api) and `src/unm_marketplace` (Flutter). Delete `src/server 20 April 2024.zip`, all old endpoint files, Stream code and keys.
- api is ESM (`"type": "module"`), listens on `PORT` (default 3000). All routes under `/api`. Errors are `{ "error": { "code": string, "message": string } }`.
- Identity only from `req.session.userId`. Body/query user IDs are never trusted.
- Conditions (exact strings): `Brand new`, `Like new`, `Lightly used`, `Well used`, `Heavily used`.
- Categories (slug, name, Material icon name), in this order: `books` Books `menu_book`; `electronics` Electronics `devices`; `home-garden` Home & Garden `chair`; `clothing-accessories` Clothing & Accessories `checkroom`; `vehicles` Vehicles `pedal_bike`; `property-rentals` Property Rentals `apartment`; `hobbies` Hobbies `sports_esports`; `entertainment` Entertainment `theaters`; `family` Family `family_restroom`; `other` Other `category`.
- Price: number 0 – 1,000,000, max 2 decimals. Displayed `RM 1,234` (decimals only if non-zero: `RM 12.50`).
- Photos: 1–6 per listing, JPEG/PNG/WebP, ≤ 5 MB each, re-encoded to WebP max 1600 px by sharp; avatar 512 px. Stored under `UPLOAD_DIR` (default `/app/uploads`), served at `/images/...`.
- Page size 24. Sort keys: `newest` (default), `price_asc`, `price_desc`.
- Copy strings are exact as in the spec (e.g. "That email is already registered.", "Email or password is wrong.", "Photos must be JPEG, PNG or WebP, up to 5 MB.", "Your listing is live.", "Nothing here yet. Be the first to sell something.", "This listing doesn't exist or was removed.", "Demo site. Data resets nightly. Built by Jun Kit").
- Demo: `SEED_DEMO=true` default; reset cron `0 3 * * *` in `Asia/Kuala_Lumpur`; `DEMO_REPLY_DELAY_MS` default 1500 (tests set 0).
- `web` binds `${WEB_BIND:-127.0.0.1:8090}:80` in prod, `8080:80` locally. Portfolio link `https://junkit.my`, GitHub `https://github.com/JunKit2003/UNM-marketplace`.
- No secrets in git; every variable in `.env.example`.

## API contract (shared by Tasks 2–9)

JSON shapes (camelCase, ISO-8601 timestamps):

- `User`: `{ id, username, firstName, lastName, displayName, email, phone, avatarUrl|null, isGuest, createdAt }` (`email`, `phone` only on `/auth/me` and `/me`; public seller = `{ id, username, displayName, avatarUrl }`).
- `Category`: `{ id, slug, name, icon, count }`.
- `Listing`: `{ id, title, description, price, condition, status: "active"|"sold", category: {id, slug, name, icon}, images: [{id, url, position}], coverUrl|null, seller: PublicUser, isSaved, isOwner, createdAt, updatedAt }`.
- `Page<T>`: `{ items: T[], page, pageSize, total, hasMore }`.
- `Conversation`: `{ id, listing: {id, title, price, status, coverUrl}, otherUser: PublicUser, lastMessage: {body, senderId, createdAt}|null, unreadCount, updatedAt }`.
- `Message`: `{ id, conversationId, senderId, body, createdAt, readAt|null }`.

| Route | Auth | Body / query | 2xx response |
|---|---|---|---|
| `GET /health` | – | – | `{ok:true}` (503 if DB down) |
| `POST /auth/signup` | – | `{firstName,lastName,username,email,phone,password}` | 201 `User` + session |
| `POST /auth/login` | – | `{email,password}` | 200 `User` |
| `POST /auth/demo` | – | – | 201 `User` (new guest) |
| `POST /auth/logout` | – | – | 204 |
| `GET /auth/me` | user | – | `User` (401 if none) |
| `PATCH /me` | user | `{firstName?,lastName?,phone?}` | `User` |
| `PUT /me/password` | non-guest | `{currentPassword,newPassword}` | 204 (403 guest, 400 wrong current) |
| `PUT /me/photo` | user | multipart `photo` | `User` |
| `GET /categories` | – | – | `Category[]` (count = active listings) |
| `GET /listings` | – | `q,category(slug),condition,min,max,sort,page,status(active default\|sold\|all)` | `Page<Listing>` |
| `GET /listings/:id` | – | – | `Listing` (404) |
| `POST /listings` | user | multipart: fields `title,description,price,categorySlug,condition` + `photos[]` (1–6) | 201 `Listing` |
| `PATCH /listings/:id` | owner | `{title?,description?,price?,categorySlug?,condition?,status?}` | `Listing` |
| `DELETE /listings/:id` | owner | – | 204 (deletes files) |
| `POST /listings/:id/images` | owner | multipart `photos[]` (total ≤ 6) | `Listing` |
| `DELETE /listings/:id/images/:imageId` | owner | – | `Listing` (400 if last photo) |
| `PUT /listings/:id/images/order` | owner | `{imageIds:[...]}` | `Listing` |
| `GET /me/listings` | user | `status` | `Listing[]` |
| `GET /me/saved` | user | – | `Listing[]` newest-saved first |
| `PUT /listings/:id/save` / `DELETE …/save` | user | – | 204 (idempotent) |
| `GET /conversations` | user | – | `Conversation[]` latest first |
| `POST /listings/:id/conversations` | user, not owner, listing active | – | 200/201 `Conversation` (same one reused) |
| `GET /conversations/:id/messages` | participant | `before` (message id), `limit` ≤ 50 | `Message[]` oldest→newest |
| `POST /conversations/:id/messages` | participant | `{body}` 1–2000 chars | 201 `Message` (REST fallback; also broadcasts) |
| `POST /conversations/:id/read` | participant | – | 204 |
| `GET /me/unread` | user | – | `{count}` |

Status codes: 400 validation (`code:"validation"`), 401 `unauthenticated`, 403 `forbidden`, 404 `not_found`, 409 `conflict`, 413 `too_large`, 429 `rate_limited`.

Socket.IO (path `/socket.io`, shares the session middleware; unauthenticated sockets are disconnected). Server joins each socket to room `user:<id>`.
- client → server: `message:send {conversationId, body}` (ack `{ok, message?|error?}`), `typing {conversationId}`, `conversation:read {conversationId}`.
- server → clients (to both participants' rooms): `message:new {message, conversationId}`, `typing {conversationId, userId}`, `conversation:read {conversationId, userId}`.

## Review Focus

- **Refreshing a deep link** (`/listing/42`, `/messages/7`) on the live site must load the app, while unknown `/api/*` paths still return JSON 404 → nginx test in Task 6.
- **A file renamed to `.jpg` that isn't an image** must give the 400 photo message, not a 500 → test in Task 3.
- **Prices typed as `1,200`, `-5`, `12.345`** must be rejected with a clear field error (client and server) → tests in Task 3 and Task 8.
- **A listing deleted while someone has a chat about it** must not break that person's inbox or thread (conversations cascade away; the open thread shows "This listing was removed.") → tests in Task 4 and Task 9.
- **Two "Try the demo" clicks at the same moment** must create two distinct guests (no username collision 500) → test in Task 2.

---

### Task 1: api foundation, database, containers

**Files:**
- Delete: `src/server/api-endpoints/`, `src/server/routes/`, `src/server/database/`, `src/server/multer-config.js`, `src/server/server.js`, `src/server 20 April 2024.zip`
- Create: `src/server/package.json`, `eslint.config.js`, `vitest.config.js`, `Dockerfile`, `.dockerignore`, `.env.example`, `src/index.js`, `src/app.js`, `src/config.js`, `src/logger.js`, `src/db/pool.js`, `src/db/migrate.js`, `migrations/001_init.sql`, `src/http/errors.js`, `src/http/validate.js`, `src/http/auth.js`, `test/setup/global.js`, `test/helpers.js`, `test/health.test.js`
- Create (root): `compose.yaml`, `.env.example`; modify `.gitignore`

**Interfaces:**
- Produces: `createApp({ pool, config }) -> { app, sessionMiddleware, io? }` (io attached in Task 4 via `attachSocket(server, …)`); `HttpError(status, code, message)`; `validate(schema, 'body'|'query') ` middleware; `requireUser`, `requireNonGuest` middleware; `migrate(pool)`; `test/helpers.js`: `makeApp()`, `resetDb()`, `agent()` (supertest agent with cookies), `createUser(overrides) -> User row`, `loginAs(agent, user)`.

Schema (`001_init.sql`, InnoDB, utf8mb4): `users(id PK, username UNIQUE, email UNIQUE NULL, first_name, last_name, phone, password_hash NULL, avatar_path NULL, is_seed BOOL, is_guest BOOL, created_at)`; `categories(id, slug UNIQUE, name, icon, position)`; `listings(id, seller_id FK users CASCADE, category_id FK, title VARCHAR(80), description TEXT, price DECIMAL(10,2), \`condition\` VARCHAR(20), status ENUM('active','sold'), is_seed, created_at, updated_at, INDEX(status, created_at), FULLTEXT(title, description))`; `listing_images(id, listing_id FK CASCADE, path, position)`; `saved_listings(user_id FK CASCADE, listing_id FK CASCADE, created_at, PK(user_id, listing_id))`; `conversations(id, listing_id FK CASCADE, buyer_id FK CASCADE, seller_id FK CASCADE, created_at, updated_at, UNIQUE(listing_id, buyer_id))`; `messages(id, conversation_id FK CASCADE, sender_id FK CASCADE, body TEXT, created_at DATETIME(3), read_at NULL, INDEX(conversation_id, id))`; `schema_migrations(name PK, applied_at)`. Sessions table is created by express-mysql-session.

- [ ] **Step 1:** `compose.yaml`: `db` (mysql:8.4, volume `db-data`, healthcheck `mysqladmin ping`, port `127.0.0.1:3307:3306` for tests, init creates `unm_test` too via `db/init/01-test-db.sql`), `api` (build `src/server`, env from `.env`, volume `uploads:/app/uploads`, depends on db healthy, healthcheck `GET /api/health`), `adminer` (profile `dev`, `127.0.0.1:8081`). `web` is added in Task 6.
- [ ] **Step 2:** Write `test/health.test.js`: `GET /api/health` → 200 `{ok:true}`; with a pool whose `query` rejects → 503; unknown `/api/nope` → 404 JSON `{error:{code:"not_found"}}`; malformed JSON body → 400 `validation`.
- [ ] **Step 3:** Run `docker compose up -d db && cd src/server && npm test` → FAIL (no app).
- [ ] **Step 4:** Implement config (zod-parsed env: `DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, SESSION_SECRET (≥32 chars in production), UPLOAD_DIR, SEED_DEMO, DEMO_REPLY_DELAY_MS, TRUST_PROXY, NODE_ENV`), pool, migrate runner (applies `migrations/*.sql` in name order, multipleStatements, records in `schema_migrations`), app (helmet without CSP, `trust proxy` when configured, json 100kb limit, session cookie `unm.sid` HttpOnly SameSite=Lax Secure in production, 30-day maxAge, MySQL store), error handler, `index.js` (migrate → seed hook placeholder → listen).
- [ ] **Step 5:** Test global setup migrates a clean `unm_test` DB; `npm test` → PASS; `npm run lint` → 0 problems.
- [ ] **Step 6:** `Dockerfile`: multi-stage `node:24-alpine`, `npm ci --omit=dev`, non-root `node` user, `EXPOSE 3000`, `CMD ["node","src/index.js"]`. Verify `docker compose up -d --build api && curl -s localhost:…/api/health` via `docker compose exec api wget -qO- localhost:3000/api/health` → `{"ok":true}`.
- [ ] **Step 7:** Commit `feat(api): Express 5 foundation, schema, compose stack`.

### Task 2: auth, guests, profile

**Files:** Create `src/modules/users/{repo.js,serialize.js}`, `src/modules/auth/routes.js`, `src/modules/me/routes.js`, `src/images/process.js` (shared sharp helper), `src/http/rateLimits.js`; tests `test/auth.test.js`, `test/me.test.js`.

**Interfaces:**
- Produces: `processImage(buffer, {maxSize}) -> Promise<Buffer webp>` throwing `HttpError(400,'validation',"Photos must be JPEG, PNG or WebP, up to 5 MB.")` on bad input; `imageUpload` multer instance (memory, 5 MB, 6 files); `saveUpload(buffer, subdir) -> relPath`, `deleteUpload(relPath)`; `serializeUser(row, {private})`; `createGuest(pool) -> userRow` (Task 5 adds the starter content via hook `onGuestCreated(user)`).

- [ ] **Step 1:** Tests: signup 201 sets cookie and `/auth/me` returns user; duplicate email → 409 message "That email is already registered."; password < 8 → 400; login wrong → 401 "Email or password is wrong."; 11th failed login in 15 min from one IP → 429; logout → `/auth/me` 401; `POST /auth/demo` twice in parallel (`Promise.all`) → two different `id` and `username`, both `isGuest:true`, `displayName` matches `/^Guest \d{4}$/`; `PATCH /me` updates name; guest `PUT /me/password` → 403; wrong current password → 400 and old password still works; `PUT /me/photo` with PNG → `avatarUrl` starts `/images/avatars/`; with a text file named `x.jpg` → 400 photo message.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement. bcrypt cost 12. Usernames: 3–30 `[a-z0-9._]`, lowercased; guest username `guest-<8 random base36>` retried on duplicate. Session regenerated on login/signup/demo. Rate limits: login 10/15 min/IP (failed only), signup 5/h, demo 10/h.
- [ ] **Step 4:** Run → PASS; lint clean.
- [ ] **Step 5:** Commit `feat(api): auth, guest demo login, profile`.

### Task 3: categories, listings, photos, saved

**Files:** Create `src/modules/categories/routes.js`, `src/modules/listings/{repo.js,serialize.js,routes.js,schemas.js}`, `src/modules/saved/routes.js`; tests `test/listings.test.js`, `test/saved.test.js`.

**Interfaces:**
- Consumes: Task 2 image helpers, `requireUser`.
- Produces: `listingsRepo.findById(id, viewerId)`, `listingsRepo.search(filters, viewerId) -> Page`, `serializeListing(row, images, viewerId)`; categories inserted by migration `002_categories.sql` (the 10 from Global Constraints).

- [ ] **Step 1:** Tests: create with 2 PNG photos → 201, `coverUrl` = first image, `isOwner:true`; 0 photos or 7 photos → 400; price `"1,200"`, `-5`, `12.345` → 400 with `fields.price`; unknown categorySlug → 400; visitor `POST /listings` → 401; non-owner PATCH/DELETE/image routes → 403 and unchanged; PATCH `status:"sold"` hides it from default `GET /listings` but `status=sold` shows it; search `q=lamp` matches title or description (FULLTEXT boolean mode with prefix `lamp*`, LIKE fallback for < 3 chars); `category`, `condition`, `min`, `max` combine; `sort=price_asc` ordered; page 2 of 30 → 6 items, `hasMore:false`; `GET /listings/999999` → 404; delete removes image files from disk; deleting the last photo → 400; reorder changes `coverUrl`; categories `count` reflects active listings; save twice → listed once; unsave idempotent; saved list ordered newest-saved; deleted listing disappears from saved; `isSaved` true for saver only.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement (all filtering/sorting/paging in SQL). **Step 4:** PASS + lint.
- [ ] **Step 5:** Commit `feat(api): listings, photos, categories, saved`.

### Task 4: chat (REST + Socket.IO) and demo seller

**Files:** Create `src/modules/chat/{repo.js,serialize.js,routes.js,socket.js,service.js,demoSeller.js}`; modify `src/index.js` (create http server, `attachSocket`); tests `test/chat.test.js`, `test/socket.test.js` (uses `socket.io-client` with the supertest cookie).

**Interfaces:**
- Produces: `chatService.sendMessage({conversationId, senderId, body}) -> Message` (persists, bumps `updated_at`, emits `message:new` to both user rooms, then calls `demoSeller.maybeReply(conversation, message)`); `chatService.startConversation(listingId, buyerId) -> Conversation`; `chatService.startSeededConversation(listingId, buyerId, sellerOpeningBody)` (used by Task 5); `attachSocket(httpServer, {sessionMiddleware, chatService}) -> io`; `setEmitter(io)`.
- `demoSeller.pickReply(listingTitle, body)`: keywords (case-insensitive) → `available|still` "Hi! Yes, the {title} is still available 🙂"; `price|discount|cheaper|lower|nego` "I can do a little off if you collect this week. What did you have in mind?"; `meet|where|collect|pickup|pick up` "I'm usually around the Trent Building or the library. Does tomorrow afternoon work?"; else "Thanks for the message! Happy to answer anything about the {title}." Emits `typing` from the seller at `delay*0.4`, sends at `delay` (`DEMO_REPLY_DELAY_MS`). Only when the recipient `is_seed` and the sender is not.

- [ ] **Step 1:** Tests: start conversation twice → same id; owner starting on own listing → 403; sold listing → 409; outsider GET messages → 403; history paging with `before`; unread count increments for recipient and `read` clears it; `/conversations` ordered by latest message and includes `otherUser` and `lastMessage`; body empty or 2001 chars → 400; deleting the listing removes the conversation from both inboxes; socket without cookie is disconnected; two sockets (buyer, seller) — buyer `message:send` → seller receives `message:new` within 2 s; `typing` relayed to the other participant only; messaging a seed seller with `DEMO_REPLY_DELAY_MS=0` produces a reply containing the listing title.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + lint.
- [ ] **Step 5:** Commit `feat(api): own chat with Socket.IO and demo seller replies`.

### Task 5: demo seed, photos, nightly reset

**Files:** Create `src/seed/{seed.js,reset.js,starter.js,data/listings.json,data/users.json,images/*.webp,CREDITS.md}`, `scripts/fetch-seed-photos.mjs` (dev-only helper, not run in CI); modify `src/index.js` (seed when `users` empty and `SEED_DEMO`; schedule reset), Task 2's guest hook; tests `test/seed.test.js`.

**Interfaces:**
- Consumes: `chatService.startSeededConversation`.
- Produces: `seedDemo(pool, {uploadDir})` (idempotent: only when no seed users), `resetDemo(pool, {uploadDir})` (truncate users/listings/images/saved/conversations/messages/sessions, wipe `uploads/listings` and `uploads/avatars`, re-seed), `giveGuestStarterContent(guest)` (saves 1 random seed listing; starts 1 seeded conversation on another seed listing where the seller wrote "Hey! Saw you checking out my {title}. Any questions, just ask 😊").

Seed content: 3 seller personas (`wei.jie` Wei Jie Tan, `priya` Priya Nair, `aisyah` Aisyah Rahman) with avatars; 30 listings spread over all 10 categories (≥2 each), UNM-flavoured titles, realistic RM prices, mixed conditions, 1–3 photos each, `created_at` spread over the last 14 days, 2 marked sold. Photos fetched once by the helper from Unsplash search, saved as 1600 px WebP, each credited in `CREDITS.md` (photographer, Unsplash URL).

- [ ] **Step 1:** Tests: `seedDemo` on empty DB → 3 seed users, 30 listings, every category ≥ 2, image files exist; running again adds nothing; `POST /auth/demo` guest has 1 saved listing and 1 conversation with 1 unread message from a seed seller; after a visitor creates a listing + messages, `resetDemo` → only seed data remains and the visitor's image files are gone, and seeded listings are back to their original status.
- [ ] **Step 2:** FAIL. **Step 3:** Run the helper, curate photos, write data, implement. **Step 4:** PASS + lint.
- [ ] **Step 5:** Commit `feat(api): demo seed data, guest starter content, nightly reset`.

### Task 6: Flutter foundation, theme, web container

**Files:** Replace `src/unm_marketplace/pubspec.yaml`, `analysis_options.yaml`; delete all of `lib/` and `assets/`; create `lib/main.dart`, `lib/app.dart`, `lib/router.dart`, `lib/core/config.dart`, `lib/core/api/{api_client.dart,models.dart,api_error.dart}`, `lib/core/repositories/{auth_repository.dart,listings_repository.dart,chat_repository.dart}`, `lib/core/realtime/chat_socket.dart`, `lib/state/{auth.dart,providers.dart}`, `lib/theme/{tokens.dart,app_theme.dart}`, `lib/widgets/{app_shell.dart,glass_panel.dart,gradient_mesh.dart,shimmer.dart,demo_banner.dart,price_text.dart,empty_state.dart,listing_card.dart}`, `assets/fonts/` (Space Grotesk, Inter, OFL), `web/index.html`, `web/manifest.json`, `web/favicon.png`, `web/icons/*`; `src/unm_marketplace/Dockerfile`, `.dockerignore`, `deploy/nginx/default.conf`; modify root `compose.yaml` (add `web` on `8080:80`); tests `test/models_test.dart`, `test/price_text_test.dart`, `test/router_test.dart`, `deploy/nginx/test.sh`.

**Interfaces:**
- Consumes: the API contract.
- Produces: `ApiClient` (Dio, base URL = `Uri.base.origin` on web or `--dart-define=API_BASE`, `withCredentials` via `BrowserHttpClientAdapter`, maps error JSON to `ApiError{status, code, message, fields}`); models `User, PublicUser, Category, Listing, ListingImage, PageResult<T>, Conversation, Message` with `fromJson`; repositories with one method per route; `ChatSocket` (connect/disconnect, `Stream<Message> messages`, `Stream<TypingEvent> typing`, `send()`, `markRead()`); Riverpod: `authProvider` (AsyncNotifier<User?> with `login, signup, demo, logout, refresh`), `apiClientProvider`, repository providers, `unreadCountProvider`; `AppTokens` (colors: ink `#0B1020`, navy `#10263B`, surface `#141B2E`, violet `#7C5CFF`, cyan `#22D3EE`, text `#E6E9F2`, muted `#8A93A8`; light-mode counterparts), `buildTheme(Brightness)`; `ListingCard(listing, onTap, onSaveToggle)` with Hero tag `listing-cover-<id>`; `PriceText` formatting per Global Constraints; `AppShell` (bottom NavigationBar < 720 px, NavigationRail ≥ 720 px; tabs Browse, Sell, Messages (badge), Saved, Profile) wrapping routes with `DemoBanner`.
- Routes: `/` browse, `/listing/:id`, `/listing/:id/edit`, `/sell`, `/saved`, `/messages`, `/messages/:id`, `/me`, `/login?from=`, `/about`. `/sell`, `/saved`, `/messages*`, `/me`, edit redirect to `/login?from=<path>` when signed out. Path URL strategy (`usePathUrlStrategy`).

- [ ] **Step 1:** Tests: `Listing.fromJson` round-trips the contract sample; `PriceText` renders `RM 1,234`, `RM 12.50`, `RM 0`; router redirects `/saved` → `/login?from=%2Fsaved` when signed out; `deploy/nginx/test.sh` (runs the built `web` image with a stub upstream): `/listing/42` → 200 HTML, `/api/nope` → proxied (502/404 from stub, not index.html), `/flutter_service_worker.js` → `Cache-Control: no-cache`, hashed assets cached.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. Dockerfile: stage `ghcr.io/cirruslabs/flutter:stable` → `flutter pub get && flutter build web --release`; stage `nginx:1-alpine` copies `build/web` and `default.conf` (gzip, `try_files $uri $uri/ /index.html`, proxy `/api/` `/images/` `/socket.io/` to `http://api:3000` with WebSocket upgrade headers and `X-Forwarded-*`, `client_max_body_size 40m`, `/images/` cached 7 d).
- [ ] **Step 4:** `flutter analyze` 0 issues; `flutter test` PASS; nginx test PASS; `docker compose up -d --build` → `http://localhost:8080` loads the shell.
- [ ] **Step 5:** Commit `feat(web): Flutter 3 foundation, theme, nginx container`.

### Task 7: Browse and listing detail

**Files:** Create `lib/features/browse/{browse_page.dart,browse_controller.dart,filter_sheet.dart,hero_header.dart,category_strip.dart}`, `lib/features/listing/{listing_detail_page.dart,gallery.dart,fullscreen_gallery.dart,seller_card.dart}`; tests `test/browse_page_test.dart`, `test/listing_detail_test.dart` (fake repositories via ProviderScope overrides).

**Interfaces:**
- Consumes: Task 6 widgets, `listingsRepository.search(BrowseFilters, page)`, `getListing(id)`, `save/unsave`, `chatRepository.start(listingId)`.
- Produces: `BrowseFilters {q, categorySlug, condition, min, max, sort}` with `toQuery()` / `fromQuery()` (URL ↔ filters).

Behaviour: hero with animated gradient mesh (slow drift + pointer parallax on desktop), headline "Buy, sell and swap on campus.", search field "What are you looking for?", "Try the demo" button when signed out; category strip with icons and counts; sort menu (Newest, Price low→high, Price high→low); filter sheet (condition chips, min/max); responsive masonry-style grid (2 cols phone → 5 cols wide), staggered fade/slide-in, shimmer skeletons, infinite scroll; empty state copy. Detail: Hero cover → swipeable gallery with dots and arrow keys, tap → fullscreen; price, condition pill, category, posted "2h ago", description, seller card, sticky action bar ("Message seller", heart, share = copy link with snackbar "Link copied"); owner sees "Edit", "Mark as sold"/"Mark as available", "Delete" (confirm dialog); sold badge; 404 copy "This listing doesn't exist or was removed."

- [ ] **Step 1:** Widget tests: grid shows cards from fake page; typing a search + choosing a category updates the URL query; scroll end requests page 2; empty result shows empty copy; detail shows price `RM 45`, owner sees Edit not Message; visitor pressing "Message seller" navigates to `/login?from=/listing/1%3Fchat%3D1`; 404 shows copy.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** analyze + test PASS.
- [ ] **Step 5:** Commit `feat(web): browse and listing detail`.

### Task 8: Auth, sell/edit, saved, profile

**Files:** Create `lib/features/auth/auth_page.dart`, `lib/features/sell/{sell_page.dart,photo_picker_grid.dart,listing_form.dart,validators.dart}`, `lib/features/saved/saved_page.dart`, `lib/features/profile/{profile_page.dart,edit_profile_sheet.dart,change_password_sheet.dart}`; tests `test/auth_page_test.dart`, `test/sell_page_test.dart`, `test/validators_test.dart`.

**Interfaces:**
- Consumes: `authProvider`, `listingsRepository.create(fields, List<PickedPhoto>)`, `update`, `addImages`, `deleteImage`, `reorderImages`, `mine`, `saved`; `image_picker` (web returns XFile bytes) + `desktop_drop` for drag-and-drop on web.
- Produces: `validatePrice(String) -> String?` (null when valid).

Behaviour: auth page with Log in / Sign up tabs, glass card over gradient, "Try the demo" button, server errors shown inline, returns to `from`. Sell: 3 steps Photos → Details → Review with a live preview `ListingCard`, reorder by drag, remove, max 6, client checks type/size with the exact photo copy; success snackbar "Your listing is live." and go to detail. Edit reuses the form, prefilled. Saved: grid of saved cards, empty "No saved listings yet. Tap the heart on anything you like." Profile: avatar (tap to change), name, "My listings" (Active / Sold tabs), edit profile, change password (hidden for guests, with note "Guest accounts can't set a password."), log out.

- [ ] **Step 1:** Tests: `validatePrice` rejects `1,200`, `-5`, `12.345`, empty, `1000001`; accepts `0`, `12.5`, `45`; sign-up error "That email is already registered." shows under email; sell step 1 blocks Next with 0 photos; adding a 6 MB fake file shows the photo copy; guest profile has no change-password.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** analyze + test PASS.
- [ ] **Step 5:** Commit `feat(web): auth, sell and edit, saved, profile`.

### Task 9: Messages, About, polish

**Files:** Create `lib/features/chat/{inbox_page.dart,thread_page.dart,message_bubble.dart,typing_dots.dart,chat_controller.dart}`, `lib/features/about/about_page.dart`; tests `test/thread_page_test.dart`, `test/inbox_page_test.dart`.

**Interfaces:**
- Consumes: `chatRepository` (list, messages(before), send, read, start), `ChatSocket`, `unreadCountProvider`.

Behaviour: inbox list (listing thumb, other user, last message, relative time, unread badge), empty "No chats yet. Find something you like and message the seller."; two-pane on ≥ 1000 px (inbox + thread). Thread: header with listing chip (tap → detail; removed listing → "This listing was removed." and input disabled), bubbles grouped by sender with times, "Seen" under last own message, animated typing dots, send on Enter, optimistic send with retry on failure, load older on scroll-top, marks read on open and on new incoming. Socket connects after login, disconnects on logout, updates unread badge live. About page: project story (2024 group project → 2026 rebuild), stack chips, architecture diagram (simple widget boxes), "What changed" list, links to GitHub and Portfolio. `DemoBanner` text exact, link opens `https://junkit.my`.

- [ ] **Step 1:** Tests: incoming socket message appears in open thread and triggers markRead; typing event shows dots then hides after 3 s; optimistic message shows then confirms; removed-listing thread disables input with copy; inbox shows unread badge count.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** analyze + test PASS.
- [ ] **Step 5:** Commit `feat(web): live chat, about page`.

### Task 10: CI/CD, prod compose, handoff docs, README

**Files:** Create `.github/workflows/ci-deploy.yml`, `compose.prod.yaml`, `deploy/remote-deploy.sh`, `deploy/nginx/host-unm.junkit.my.conf` (example for the VPS agent), `docs/deploy-handoff.md`; rewrite `README.md`; remove `.vscode/launch.json` references to old paths if broken.

**Interfaces:**
- `compose.prod.yaml`: `db`, `api` (`image: ghcr.io/junkit2003/unm-marketplace-api:${IMAGE_TAG}`), `web` (`…-web:${IMAGE_TAG}`, ports `${WEB_BIND:-127.0.0.1:8090}:80`), restart `unless-stopped`, named volumes, `.env` from the deploy dir.
- `deploy/remote-deploy.sh <tag>`: in `$DEPLOY_PATH` (default `~/apps/unm-marketplace`): remember current tag from `.current_tag`, `IMAGE_TAG=<tag> docker compose -f compose.prod.yaml pull && up -d`, poll `http://${WEB_BIND}/api/health` for 90 s; success → write `.current_tag`, `docker image prune -f`; failure → redeploy previous tag and exit 1.

Workflow: triggers `pull_request`, `push` to `main`, `workflow_dispatch` (input `image_tag`). Jobs: `api` (ubuntu, MySQL 8.4 service, Node 24, `npm ci`, lint, test); `web` (subosito/flutter-action stable, `flutter pub get`, `analyze`, `test`); `images` (needs both; buildx build both Dockerfiles with GHA cache; on `main` push to GHCR tags `<sha>` and `latest`, `permissions: packages: write`); `deploy` (main or dispatch, needs images, `concurrency: deploy`; secrets `DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY, DEPLOY_PORT`, var `DEPLOY_PATH`; scp `compose.prod.yaml` + `deploy/remote-deploy.sh`, then ssh run with tag = dispatch input or sha).

- [ ] **Step 1:** `bash -n deploy/remote-deploy.sh`; run `actionlint` via `docker run --rm -v $PWD:/repo rhysd/actionlint` → 0 errors; `docker compose -f compose.prod.yaml config` with sample env → valid.
- [ ] **Step 2:** Local dry run of `remote-deploy.sh` against locally built images tagged `local` with a fake previous tag and a broken api (bad DB password) → rolls back and exits 1; good tag → writes `.current_tag`.
- [ ] **Step 3:** Handoff doc for the VPS agent: prerequisites, `.env` keys (generate `SESSION_SECRET` with `openssl rand -hex 32`), host nginx example (TLS via certbot, WebSocket upgrade, `client_max_body_size 40m`, proxy to `127.0.0.1:8090`), GitHub secrets/vars, GHCR packages set public after first push, first deploy and rollback commands. README: screenshots, features, stack, quick start (`cp .env.example .env && docker compose up -d`), tests, links.
- [ ] **Step 4:** Commit `ci: build, test, publish and deploy pipeline with rollback`.

### Task 11: End-to-end verification and review

- [ ] **Step 1:** Fresh `docker compose down -v && docker compose up -d --build`; walk RV-01 … RV-08 with Playwright against `http://localhost:8080` (two browser contexts for chat), screenshots at 390 px and 1440 px for README and PR (`docs/screenshots/`).
- [ ] **Step 2:** Fix anything found (each fix with a test), re-run api and Flutter suites.
- [ ] **Step 3:** Whole-branch review by a fresh reviewer; address findings.
- [ ] **Step 4:** Push branch, open PR to `main` with summary, screenshots, test evidence and the Stream-key warning.
