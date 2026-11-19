import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import { agent, closePool, makeApp, resetDb, tempUploadDir, testConfig } from './helpers.js';
import { postListing, signupBody } from './fixtures.js';

afterAll(closePool);
beforeEach(resetDb);

async function setup() {
  const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: await tempUploadDir() }) });
  const seller = agent(app);
  await seller.post('/api/auth/signup').send(signupBody(1));
  const buyer = agent(app);
  await buyer.post('/api/auth/signup').send(signupBody(2));
  const a = (await postListing(seller, { title: 'Lamp A' })).body;
  const b = (await postListing(seller, { title: 'Lamp B' })).body;
  return { app, seller, buyer, a, b };
}

describe('saved listings', () => {
  it('saving twice keeps one entry', async () => {
    const { buyer, a } = await setup();
    expect((await buyer.put(`/api/listings/${a.id}/save`)).status).toBe(204);
    expect((await buyer.put(`/api/listings/${a.id}/save`)).status).toBe(204);
    const res = await buyer.get('/api/me/saved');
    expect(res.body.map((l) => l.id)).toEqual([a.id]);
    expect(res.body[0].isSaved).toBe(true);
  });

  it('orders newest-saved first', async () => {
    const { buyer, a, b } = await setup();
    await buyer.put(`/api/listings/${b.id}/save`);
    await new Promise((r) => setTimeout(r, 15));
    await buyer.put(`/api/listings/${a.id}/save`);
    expect((await buyer.get('/api/me/saved')).body.map((l) => l.title)).toEqual(['Lamp A', 'Lamp B']);
  });

  it('unsaving is idempotent', async () => {
    const { buyer, a } = await setup();
    await buyer.put(`/api/listings/${a.id}/save`);
    expect((await buyer.delete(`/api/listings/${a.id}/save`)).status).toBe(204);
    expect((await buyer.delete(`/api/listings/${a.id}/save`)).status).toBe(204);
    expect((await buyer.get('/api/me/saved')).body).toEqual([]);
  });

  it('drops a listing from Saved when its owner deletes it', async () => {
    const { buyer, seller, a } = await setup();
    await buyer.put(`/api/listings/${a.id}/save`);
    await seller.delete(`/api/listings/${a.id}`);
    expect((await buyer.get('/api/me/saved')).body).toEqual([]);
  });

  it('marks isSaved only for the person who saved it', async () => {
    const { app, buyer, seller, a } = await setup();
    await buyer.put(`/api/listings/${a.id}/save`);
    expect((await buyer.get(`/api/listings/${a.id}`)).body.isSaved).toBe(true);
    expect((await seller.get(`/api/listings/${a.id}`)).body.isSaved).toBe(false);
    expect((await request(app).get('/api/listings')).body.items.every((l) => l.isSaved === false)).toBe(true);
    const browse = await buyer.get('/api/listings');
    expect(browse.body.items.find((l) => l.id === a.id).isSaved).toBe(true);
  });

  it('returns 404 when saving an unknown listing and 401 when logged out', async () => {
    const { app, buyer } = await setup();
    expect((await buyer.put('/api/listings/999999/save')).status).toBe(404);
    expect((await request(app).put('/api/listings/1/save')).status).toBe(401);
  });
});
