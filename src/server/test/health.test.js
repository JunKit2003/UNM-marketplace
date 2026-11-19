import { afterAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { closePool, makeApp } from './helpers.js';

afterAll(closePool);

describe('health and error handling', () => {
  it('reports ok when the database answers', async () => {
    const { app } = makeApp();
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });
  });

  it('reports 503 when the database is down', async () => {
    const brokenPool = { query: async () => { throw new Error('ECONNREFUSED'); } };
    const { app } = makeApp({ pool: brokenPool, sessionStore: 'memory' });
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(503);
    expect(res.body).toEqual({ ok: false });
  });

  it('answers unknown api paths with a JSON 404', async () => {
    const { app } = makeApp();
    const res = await request(app).get('/api/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('not_found');
  });

  it('answers malformed JSON with a 400 validation error', async () => {
    const { app } = makeApp();
    const res = await request(app)
      .post('/api/health')
      .set('Content-Type', 'application/json')
      .send('{"broken":');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation');
  });
});
