// Browser walkthrough of the acceptance spec (RV-01 … RV-08) against a running stack,
// plus the README screenshots. Uses Flutter's accessibility tree to find things.
//
//   docker compose up -d --build
//   npm ci --prefix e2e   (PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 is fine; the image has browsers)
//   docker run --rm --network host --user "$(id -u):$(id -g)" -e HOME=/tmp \
//     -e BASE=http://localhost:8080 -v "$PWD":/repo -w /repo/e2e \
//     mcr.microsoft.com/playwright:v1.65.1-noble node showcase.mjs
import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium } from 'playwright';

const BASE = process.env.BASE ?? 'http://localhost:8080';
const SHOTS = process.env.SHOTS ?? '../docs/screenshots';
const PHOTO = process.env.PHOTO ?? '../src/server/src/seed/images/desk-lamp.webp';
// 401: signed-out session check. 404: the deliberate unknown-listing check.
// gstatic/cert: Flutter's fallback font CDN, blocked by TLS inspection on some networks.
const IGNORED_CONSOLE = [/status of 401/, /status of 404/, /fonts\.gstatic\.com/, /ERR_CERT_AUTHORITY_INVALID/];

const results = [];
const pageErrors = [];
async function check(name, fn) {
  try {
    await fn();
    results.push([true, name]);
    console.log(`ok   - ${name}`);
  } catch (err) {
    results.push([false, name]);
    console.log(`FAIL - ${name}\n       ${String(err.message).split('\n')[0]}`);
  }
}
const expect = (cond, msg) => { if (!cond) throw new Error(msg); };

const browser = await chromium.launch();
await fs.mkdir(SHOTS, { recursive: true });

async function newContext(opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, ...opts });
  ctx.on('page', (p) => {
    p.on('pageerror', (e) => pageErrors.push(e.message));
    p.on('console', (m) => {
      if (m.type() === 'error' && !IGNORED_CONSOLE.some((r) => r.test(m.text()))) pageErrors.push(m.text());
    });
  });
  return ctx;
}

async function open(page, url, { settle = 2500 } = {}) {
  await page.goto(BASE + url);
  await page.waitForSelector('flutter-view', { timeout: 30_000 });
  await page.waitForTimeout(settle);
  // Turn on Flutter's accessibility tree (retry: the placeholder appears after the first frame).
  for (let i = 0; i < 10 && (await page.locator('flt-semantics').count()) < 5; i++) {
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    await page.waitForTimeout(500);
  }
}

// Flutter exposes some text as nodes and some as aria-labels (merged into buttons).
const css = (t) => t.replace(/["\\]/g, '\\$&');
const text = (page, t) => page.getByText(t, { exact: false }).or(page.locator(`[aria-label*="${css(t)}"]`)).first();
const button = (page, name) => page.getByRole('button', { name }).first();
async function waitText(page, t, timeout = 8000) {
  await text(page, t).waitFor({ state: 'attached', timeout });
}
async function shot(page, name) {
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(SHOTS, `${name}.png`) });
}
async function api(ctx, method, url, body) {
  const r = await ctx.request[method](BASE + url, body ? { data: body } : undefined);
  return { status: r.status(), body: r.status() === 204 ? null : await r.json().catch(() => null) };
}
async function type(page, label, value) {
  const box = page.getByRole('textbox', { name: label }).first();
  await box.click();
  // Flutter swaps in a real <input> on focus; the first keys are lost if we type too soon.
  await page.waitForTimeout(400);
  await page.keyboard.type(value, { delay: 15 });
}

// ---------- Desktop visitor ----------
const visitor = await newContext();
const vp = await visitor.newPage();

await check('RV02 browse shows the hero and demo listings', async () => {
  await open(vp, '/');
  await waitText(vp, 'Buy, sell and swap on campus.');
  const cards = await vp.getByRole('button', { name: /RM [\d,]+/ }).count();
  expect(cards >= 10, `only ${cards} listing cards`);
});
await shot(vp, 'browse-desktop');

await check('RV02 choosing a category updates the URL and results', async () => {
  await vp.getByRole('checkbox', { name: /^Books/ }).first().click();
  await vp.waitForTimeout(2000);
  expect(vp.url().includes('category=books'), `url is ${vp.url()}`);
  await waitText(vp, 'Calculus');
  expect((await vp.getByRole('button', { name: /MacBook/ }).count()) === 0, 'MacBook still listed under Books');
});

const macbook = (await api(visitor, 'get', '/api/listings?q=macbook')).body.items[0];
await check('RV02 a listing has its own shareable page', async () => {
  await open(vp, `/listing/${macbook.id}`);
  await waitText(vp, 'About this item');
  await button(vp, 'Message seller').waitFor({ state: 'attached' });
});
await shot(vp, 'listing-desktop');

await check('RV02 unknown listing shows the removed copy', async () => {
  await open(vp, '/listing/999999');
  await waitText(vp, "This listing doesn't exist or was removed.");
});

await check('RV03 protected pages send visitors to log in and remember where', async () => {
  await open(vp, '/saved');
  const from = new URL(vp.url()).searchParams.get('from');
  expect(new URL(vp.url()).pathname === '/login' && from === '/saved', `url is ${vp.url()}`);
});

// ---------- Desktop guest (Try the demo) ----------
await check('RV08 Try the demo signs in a fresh guest with starter content', async () => {
  await open(vp, '/');
  await button(vp, 'Try the demo').click();
  await vp.waitForTimeout(2500);
  const me = await api(visitor, 'get', '/api/auth/me');
  expect(me.status === 200 && me.body.isGuest, 'not signed in as a guest');
  expect(/^Guest \d{4}$/.test(me.body.displayName), me.body.displayName);
  const saved = await api(visitor, 'get', '/api/me/saved');
  expect(saved.body.length === 1, `saved has ${saved.body.length}`);
  const inbox = await api(visitor, 'get', '/api/conversations');
  expect(inbox.body.length === 1 && inbox.body[0].unreadCount === 1, 'no waiting chat');
});

const [starter] = (await api(visitor, 'get', '/api/conversations')).body;
await check('RV08 demo seller shows typing, then replies about the listing', async () => {
  await open(vp, `/messages/${starter.id}`);
  await waitText(vp, 'Hey! Saw you checking out');
  await type(vp, 'Write a message…', 'Is it still available?');
  await vp.keyboard.press('Enter');
  await waitText(vp, 'Is it still available?');
  await waitText(vp, 'is still available 🙂', 6000);
  const msgs = await api(visitor, 'get', `/api/conversations/${starter.id}/messages`);
  expect(msgs.body.at(-1).body.includes(starter.listing.title), 'reply does not mention the listing');
});
await shot(vp, 'chat-desktop');

// ---------- Two people chatting live ----------
const seller = await newContext();
await api(seller, 'post', '/api/auth/demo');
const photo = await fs.readFile(PHOTO);
const created = await seller.request.post(`${BASE}/api/listings`, {
  multipart: {
    title: 'E2E desk fan', description: 'Quiet three-speed fan.', price: '40', categorySlug: 'home-garden', condition: 'Like new',
    photos: { name: 'fan.webp', mimeType: 'image/webp', buffer: photo },
  },
});
const fan = await created.json();

await check('RV04 owners can post a listing through the API with a photo', async () => {
  expect(created.status() === 201, `status ${created.status()}`);
  expect(fan.coverUrl?.startsWith('/images/listings/'), fan.coverUrl);
});

await check('RV06 a message reaches the other person live, within 2 seconds', async () => {
  const conv = (await api(visitor, 'post', `/api/listings/${fan.id}/conversations`)).body;
  const sp = await seller.newPage();
  await open(sp, `/messages/${conv.id}`);
  await sp.waitForTimeout(1500); // socket connected
  const sentAt = Date.now();
  await api(visitor, 'post', `/api/conversations/${conv.id}/messages`, { body: 'Hello from the other tab' });
  await waitText(sp, 'Hello from the other tab', 2000);
  console.log(`       delivered in ${Date.now() - sentAt} ms`);
});

await check('RV04 others cannot edit or delete someone else\'s listing', async () => {
  expect((await api(visitor, 'patch', `/api/listings/${fan.id}`, { title: 'Mine now' })).status === 403, 'PATCH allowed');
  expect((await api(visitor, 'delete', `/api/listings/${fan.id}`)).status === 403, 'DELETE allowed');
});

await check('RV06 outsiders cannot read a conversation', async () => {
  const outsider = await newContext();
  await api(outsider, 'post', '/api/auth/demo');
  const r = await api(outsider, 'get', `/api/conversations/${starter.id}/messages`);
  expect(r.status === 403, `status ${r.status}`);
  await outsider.close();
});

// ---------- Phone ----------
const phone = await newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
const pp = await phone.newPage();

await check('phone: browse renders with bottom navigation', async () => {
  await open(pp, '/');
  await waitText(pp, 'Buy, sell and swap on campus.');
  await text(pp, 'Browse').waitFor({ state: 'attached' });
});
await shot(pp, 'browse-phone');

await open(pp, '/login');
await shot(pp, 'login-phone');

await check('RV04 sell flow on a phone: photo → details → review → publish', async () => {
  await api(phone, 'post', '/api/auth/demo');
  await open(pp, '/sell');
  const chooser = pp.waitForEvent('filechooser', { timeout: 8000 });
  await button(pp, 'Add photos').click();
  await (await chooser).setFiles(PHOTO);
  await pp.waitForTimeout(1500);
  await button(pp, 'Next').click();
  await pp.waitForTimeout(800);
  await type(pp, 'Title', 'Barely used desk lamp');
  await type(pp, 'Price', '38');
  await pp.getByRole('button', { name: /Category/ }).first().click();
  await pp.waitForTimeout(600);
  await pp.getByRole('menuitem', { name: 'Home & Garden' }).first().click().catch(async () => {
    await text(pp, 'Home & Garden').click();
  });
  await pp.waitForTimeout(600);
  await type(pp, 'Description', 'Warm light, three brightness levels.');
  await button(pp, 'Next').click();
  await waitText(pp, 'how buyers will see it');
  await shot(pp, 'sell-phone');
  await button(pp, 'Publish').click();
  await waitText(pp, 'Your listing is live.');
  await pp.waitForTimeout(1500);
  expect(/\/listing\/\d+$/.test(pp.url()), `url is ${pp.url()}`);
});

await check('phone: chat thread', async () => {
  const [c] = (await api(phone, 'get', '/api/conversations')).body;
  await open(pp, `/messages/${c.id}`);
  await type(pp, 'Write a message…', 'Where can we meet?');
  await pp.keyboard.press('Enter');
  await waitText(pp, 'Trent Building', 10000);
});
await shot(pp, 'chat-phone');

await check('no uncaught errors in the browser', async () => {
  expect(pageErrors.length === 0, pageErrors.slice(0, 3).join(' | '));
});

await browser.close();
const failed = results.filter(([ok]) => !ok).length;
console.log(`\n${results.length - failed}/${results.length} checks passed`);
process.exit(failed ? 1 : 0);
