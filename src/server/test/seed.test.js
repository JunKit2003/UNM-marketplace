import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import fs from 'node:fs/promises';
import path from 'node:path';
import { agent, closePool, getPool, makeApp, resetDb, tempUploadDir, testConfig } from './helpers.js';
import { postListing, signupBody } from './fixtures.js';
import { resetDemo, seedDemo } from '../src/seed/seed.js';
import seedListings from '../src/seed/data/listings.json' with { type: 'json' };

const N = seedListings.length;

afterAll(closePool);
beforeEach(resetDb);

const count = async (sql, params = []) => Number((await getPool().query(sql, params))[0][0].n);

describe('seedDemo', () => {
  it('creates three sellers and every seed listing across every category, with photos on disk', async () => {
    const dir = await tempUploadDir();
    await seedDemo(getPool(), { uploadDir: dir });
    expect(await count('SELECT COUNT(*) n FROM users WHERE is_seed')).toBe(3);
    expect(N).toBeGreaterThanOrEqual(25);
    expect(await count('SELECT COUNT(*) n FROM listings WHERE is_seed')).toBe(N);
    expect(await count("SELECT COUNT(*) n FROM listings WHERE status = 'sold'")).toBe(2);
    const [cats] = await getPool().query(
      'SELECT c.slug, COUNT(l.id) n FROM categories c LEFT JOIN listings l ON l.category_id = c.id GROUP BY c.id',
    );
    for (const c of cats) expect(Number(c.n), c.slug).toBeGreaterThanOrEqual(2);
    const [imgs] = await getPool().query('SELECT path FROM listing_images');
    expect(imgs.length).toBeGreaterThanOrEqual(N);
    for (const { path: rel } of imgs) await fs.access(path.join(dir, rel));
    const [users] = await getPool().query('SELECT avatar_path, password_hash FROM users WHERE is_seed');
    for (const u of users) {
      expect(u.password_hash).toBeNull();
      await fs.access(path.join(dir, u.avatar_path));
    }
  });

  it('spreads listings over the last 14 days', async () => {
    await seedDemo(getPool(), { uploadDir: await tempUploadDir() });
    const [[r]] = await getPool().query(
      'SELECT TIMESTAMPDIFF(HOUR, MIN(created_at), MAX(created_at)) span, MAX(created_at) <= NOW(3) notFuture FROM listings',
    );
    expect(Number(r.span)).toBeGreaterThan(24 * 7);
    expect(Number(r.span)).toBeLessThanOrEqual(24 * 14);
    expect(Number(r.notFuture)).toBe(1);
  });

  it('does nothing the second time', async () => {
    const dir = await tempUploadDir();
    expect(await seedDemo(getPool(), { uploadDir: dir })).toBe(true);
    expect(await seedDemo(getPool(), { uploadDir: dir })).toBe(false);
    expect(await count('SELECT COUNT(*) n FROM listings')).toBe(N);
  });
});

describe('guest starter content', () => {
  it('gives each new guest one saved listing and one chat from a demo seller', async () => {
    const dir = await tempUploadDir();
    await seedDemo(getPool(), { uploadDir: dir });
    const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir, SEED_DEMO: 'true' }) });
    const guest = agent(app);
    await guest.post('/api/auth/demo');
    const saved = await guest.get('/api/me/saved');
    expect(saved.body).toHaveLength(1);
    const inbox = await guest.get('/api/conversations');
    expect(inbox.body).toHaveLength(1);
    expect(inbox.body[0].unreadCount).toBe(1);
    expect(inbox.body[0].lastMessage.body).toMatch(/^Hey! Saw you checking out my .+\. Any questions, just ask 😊$/);
    expect(inbox.body[0].listing.id).not.toBe(saved.body[0].id);
    expect((await guest.get('/api/me/unread')).body.count).toBe(1);
  });

  it('is skipped when demo mode is off', async () => {
    await seedDemo(getPool(), { uploadDir: await tempUploadDir() });
    const { app } = makeApp();
    const guest = agent(app);
    await guest.post('/api/auth/demo');
    expect((await guest.get('/api/me/saved')).body).toEqual([]);
  });
});

describe('resetDemo', () => {
  it('removes everything visitors made and restores the seed', async () => {
    const dir = await tempUploadDir();
    const pool = getPool();
    await seedDemo(pool, { uploadDir: dir });
    const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir, SEED_DEMO: 'true' }) });

    const visitor = agent(app);
    await visitor.post('/api/auth/signup').send(signupBody(1));
    const mine = (await postListing(visitor, { title: 'Visitor lamp' })).body;
    const visitorFile = path.join(dir, mine.coverUrl.replace('/images/', ''));
    await fs.access(visitorFile);
    const guest = agent(app);
    await guest.post('/api/auth/demo');
    const [conv] = (await guest.get('/api/conversations')).body;
    await guest.post(`/api/conversations/${conv.id}/messages`).send({ body: 'hello' });
    await pool.query("UPDATE listings SET status = 'active', title = 'Changed' WHERE is_seed AND status = 'sold'");

    await resetDemo(pool, { uploadDir: dir });

    expect(await count('SELECT COUNT(*) n FROM users')).toBe(3);
    expect(await count('SELECT COUNT(*) n FROM listings')).toBe(N);
    expect(await count("SELECT COUNT(*) n FROM listings WHERE status = 'sold'")).toBe(2);
    expect(await count("SELECT COUNT(*) n FROM listings WHERE title = 'Changed'")).toBe(0);
    expect(await count('SELECT COUNT(*) n FROM messages')).toBe(0);
    expect(await count('SELECT COUNT(*) n FROM conversations')).toBe(0);
    expect(await count('SELECT COUNT(*) n FROM saved_listings')).toBe(0);
    await expect(fs.access(visitorFile)).rejects.toThrow();
    expect((await visitor.get('/api/auth/me')).status).toBe(401);
  });
});
