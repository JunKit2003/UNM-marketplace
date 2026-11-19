import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import fs from 'node:fs/promises';
import path from 'node:path';
import request from 'supertest';
import { agent, closePool, getPool, makeApp, resetDb, tempUploadDir, testConfig } from './helpers.js';
import { notAnImage, pngBuffer, postListing, signupBody } from './fixtures.js';

afterAll(closePool);
beforeEach(resetDb);

async function setup() {
  const dir = await tempUploadDir();
  const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir }) });
  const seller = agent(app);
  await seller.post('/api/auth/signup').send(signupBody(1));
  const other = agent(app);
  await other.post('/api/auth/signup').send(signupBody(2));
  return { app, dir, seller, other };
}

describe('create listing', () => {
  it('publishes with photos and returns the contract shape', async () => {
    const { seller } = await setup();
    const res = await postListing(seller, {}, 2);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      title: 'Desk lamp',
      price: 45,
      condition: 'Like new',
      status: 'active',
      category: { slug: 'home-garden', name: 'Home & Garden', icon: 'chair' },
      seller: { username: 'amy1', displayName: 'Amy Tester1' },
      isOwner: true,
      isSaved: false,
    });
    expect(res.body.images).toHaveLength(2);
    expect(res.body.coverUrl).toBe(res.body.images[0].url);
    expect(res.body.images[0].url).toMatch(/^\/images\/listings\/[a-f0-9-]+\.webp$/);
  });

  it('needs at least one and at most six photos', async () => {
    const { seller } = await setup();
    expect((await postListing(seller, {}, 0)).status).toBe(400);
    const seven = await postListing(seller, {}, 7);
    expect(seven.status).toBe(400);
    expect(seven.body.error.message).toBe('A listing can have up to 6 photos.');
  });

  it.each(['1,200', '-5', '12.345', '', '1000001', 'abc'])('rejects price %j', async (price) => {
    const { seller } = await setup();
    const res = await postListing(seller, { price });
    expect(res.status).toBe(400);
    expect(res.body.error.fields.price).toBeDefined();
  });

  it.each(['0', '12.5', '1000000'])('accepts price %j', async (price) => {
    const { seller } = await setup();
    expect((await postListing(seller, { price })).status).toBe(201);
  });

  it('rejects an unknown category and condition', async () => {
    const { seller } = await setup();
    const a = await postListing(seller, { categorySlug: 'weapons' });
    expect(a.body.error.fields.categorySlug).toBeDefined();
    const b = await postListing(seller, { condition: 'Mint' });
    expect(b.body.error.fields.condition).toBeDefined();
  });

  it('rejects a non-image renamed to .jpg with the photo message', async () => {
    const { seller } = await setup();
    let req = seller.post('/api/listings');
    for (const [k, v] of Object.entries({ title: 'Old phone', description: 'Y', price: '1', categorySlug: 'books', condition: 'Brand new' })) req = req.field(k, v);
    const res = await req.attach('photos', notAnImage, { filename: 'x.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(400);
    expect(res.body.error.message).toBe('Photos must be JPEG, PNG or WebP, up to 5 MB.');
  });

  it('requires login', async () => {
    const { app } = await setup();
    const res = await postListing(request.agent(app));
    expect(res.status).toBe(401);
  });
});

describe('ownership', () => {
  it('refuses edits, deletes and photo changes by anyone but the owner', async () => {
    const { seller, other } = await setup();
    const { body: l } = await postListing(seller, {}, 2);
    expect((await other.patch(`/api/listings/${l.id}`).send({ title: 'Mine now' })).status).toBe(403);
    expect((await other.delete(`/api/listings/${l.id}`)).status).toBe(403);
    expect((await other.delete(`/api/listings/${l.id}/images/${l.images[0].id}`)).status).toBe(403);
    expect((await other.put(`/api/listings/${l.id}/images/order`).send({ imageIds: [l.images[1].id, l.images[0].id] })).status).toBe(403);
    expect((await other.post(`/api/listings/${l.id}/images`).attach('photos', await pngBuffer(), 'z.png')).status).toBe(403);
    const after = await seller.get(`/api/listings/${l.id}`);
    expect(after.body.title).toBe('Desk lamp');
    expect(after.body.images).toHaveLength(2);
  });

  it('lets the owner edit fields', async () => {
    const { seller } = await setup();
    const { body: l } = await postListing(seller);
    const res = await seller.patch(`/api/listings/${l.id}`).send({ title: 'Brighter lamp', price: 50, categorySlug: 'electronics' });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ title: 'Brighter lamp', price: 50, category: { slug: 'electronics' } });
  });

  it('shows isOwner only to the owner', async () => {
    const { seller, other, app } = await setup();
    const { body: l } = await postListing(seller);
    expect((await other.get(`/api/listings/${l.id}`)).body.isOwner).toBe(false);
    expect((await request(app).get(`/api/listings/${l.id}`)).body.isOwner).toBe(false);
  });
});

describe('photos', () => {
  it('deletes image files from disk with the listing', async () => {
    const { seller, dir } = await setup();
    const { body: l } = await postListing(seller, {}, 2);
    const files = l.images.map((i) => path.join(dir, i.url.replace('/images/', '')));
    await fs.access(files[0]);
    expect((await seller.delete(`/api/listings/${l.id}`)).status).toBe(204);
    for (const f of files) await expect(fs.access(f)).rejects.toThrow();
    expect((await seller.get(`/api/listings/${l.id}`)).status).toBe(404);
  });

  it('refuses to delete the last photo', async () => {
    const { seller } = await setup();
    const { body: l } = await postListing(seller, {}, 1);
    const res = await seller.delete(`/api/listings/${l.id}/images/${l.images[0].id}`);
    expect(res.status).toBe(400);
    expect(res.body.error.message).toBe('A listing needs at least one photo.');
  });

  it('adds photos up to six in total', async () => {
    const { seller } = await setup();
    const { body: l } = await postListing(seller, {}, 5);
    const ok = await seller.post(`/api/listings/${l.id}/images`).attach('photos', await pngBuffer(), 'a.png');
    expect(ok.status).toBe(200);
    expect(ok.body.images).toHaveLength(6);
    const tooMany = await seller.post(`/api/listings/${l.id}/images`).attach('photos', await pngBuffer(), 'b.png');
    expect(tooMany.status).toBe(400);
  });

  it('reorders photos and the first becomes the cover', async () => {
    const { seller } = await setup();
    const { body: l } = await postListing(seller, {}, 3);
    const ids = l.images.map((i) => i.id).reverse();
    const res = await seller.put(`/api/listings/${l.id}/images/order`).send({ imageIds: ids });
    expect(res.status).toBe(200);
    expect(res.body.images.map((i) => i.id)).toEqual(ids);
    expect(res.body.coverUrl).toBe(res.body.images[0].url);
  });

  it('rejects an order that is not exactly the listing\'s photos', async () => {
    const { seller } = await setup();
    const { body: l } = await postListing(seller, {}, 2);
    const res = await seller.put(`/api/listings/${l.id}/images/order`).send({ imageIds: [l.images[0].id] });
    expect(res.status).toBe(400);
  });
});

describe('browse', () => {
  async function many(seller, items) {
    const out = [];
    for (const it of items) out.push((await postListing(seller, it)).body);
    return out;
  }

  it('lists newest first, 24 per page', async () => {
    const { seller, app } = await setup();
    const pool = getPool();
    // Insert 30 listings directly for speed, with spread-out timestamps.
    const { body: first } = await postListing(seller, { title: 'Oldest real' });
    const [[cat]] = await pool.query("SELECT id FROM categories WHERE slug='books'");
    for (let i = 0; i < 29; i++) {
      await pool.query(
        `INSERT INTO listings (seller_id, category_id, title, description, price, \`condition\`, created_at)
         VALUES (?, ?, ?, 'd', 10, 'Brand new', NOW(3) + INTERVAL ? SECOND)`,
        [first.seller.id, cat.id, `Book ${i}`, i + 1],
      );
    }
    const p1 = await request(app).get('/api/listings');
    expect(p1.body).toMatchObject({ page: 1, pageSize: 24, total: 30, hasMore: true });
    expect(p1.body.items).toHaveLength(24);
    expect(p1.body.items[0].title).toBe('Book 28');
    const p2 = await request(app).get('/api/listings?page=2');
    expect(p2.body.items).toHaveLength(6);
    expect(p2.body.hasMore).toBe(false);
    expect(p2.body.items.at(-1).title).toBe('Oldest real');
  });

  it('combines search, category, condition and price filters', async () => {
    const { seller, app } = await setup();
    await many(seller, [
      { title: 'Desk lamp', categorySlug: 'home-garden', price: '45', condition: 'Like new' },
      { title: 'Floor lamp', categorySlug: 'home-garden', price: '120', condition: 'Well used' },
      { title: 'Lamp textbook', description: 'About lighting', categorySlug: 'books', price: '30' },
      { title: 'Kettle', description: 'Comes with a lamp-shaped box', categorySlug: 'home-garden', price: '20' },
    ]);
    const res = await request(app).get('/api/listings?q=lamp&category=home-garden&max=100&sort=price_asc');
    expect(res.body.items.map((l) => l.title)).toEqual(['Kettle', 'Desk lamp']);
    const used = await request(app).get('/api/listings?q=lamp&condition=Well%20used');
    expect(used.body.items.map((l) => l.title)).toEqual(['Floor lamp']);
    const min = await request(app).get('/api/listings?min=40&sort=price_desc');
    expect(min.body.items.map((l) => l.title)).toEqual(['Floor lamp', 'Desk lamp']);
  });

  it('matches short searches too', async () => {
    const { seller, app } = await setup();
    await many(seller, [{ title: 'TV stand' }, { title: 'Chair' }]);
    const res = await request(app).get('/api/listings?q=tv');
    expect(res.body.items.map((l) => l.title)).toEqual(['TV stand']);
  });

  it('hides sold listings by default and shows them on request', async () => {
    const { seller, app } = await setup();
    const [a] = await many(seller, [{ title: 'Sold bike', categorySlug: 'vehicles' }, { title: 'Active bike', categorySlug: 'vehicles' }]);
    expect((await seller.patch(`/api/listings/${a.id}`).send({ status: 'sold' })).body.status).toBe('sold');
    const def = await request(app).get('/api/listings');
    expect(def.body.items.map((l) => l.title)).toEqual(['Active bike']);
    const sold = await request(app).get('/api/listings?status=sold');
    expect(sold.body.items.map((l) => l.title)).toEqual(['Sold bike']);
  });

  it('rejects bad query values', async () => {
    const { app } = await setup();
    expect((await request(app).get('/api/listings?sort=random')).status).toBe(400);
    expect((await request(app).get('/api/listings?page=0')).status).toBe(400);
  });

  it('returns 404 for an unknown listing', async () => {
    const { app } = await setup();
    const res = await request(app).get('/api/listings/999999');
    expect(res.status).toBe(404);
    expect(res.body.error.message).toBe("This listing doesn't exist or was removed.");
    expect((await request(app).get('/api/listings/abc')).status).toBe(404);
  });

  it('lists my listings filtered by status', async () => {
    const { seller, other } = await setup();
    const [a] = await many(seller, [{ title: 'One' }, { title: 'Two' }]);
    await postListing(other, { title: 'Not mine' });
    await seller.patch(`/api/listings/${a.id}`).send({ status: 'sold' });
    expect((await seller.get('/api/me/listings')).body.map((l) => l.title).sort()).toEqual(['One', 'Two']);
    expect((await seller.get('/api/me/listings?status=sold')).body.map((l) => l.title)).toEqual(['One']);
  });
});

describe('categories', () => {
  it('lists the ten categories in order with active counts', async () => {
    const { seller, app } = await setup();
    await postListing(seller, { categorySlug: 'books' });
    const { body: sold } = await postListing(seller, { categorySlug: 'books' });
    await seller.patch(`/api/listings/${sold.id}`).send({ status: 'sold' });
    const res = await request(app).get('/api/categories');
    expect(res.body.map((c) => c.slug)).toEqual([
      'books', 'electronics', 'home-garden', 'clothing-accessories', 'vehicles',
      'property-rentals', 'hobbies', 'entertainment', 'family', 'other',
    ]);
    expect(res.body[0]).toMatchObject({ slug: 'books', name: 'Books', icon: 'menu_book', count: 1 });
  });
});
