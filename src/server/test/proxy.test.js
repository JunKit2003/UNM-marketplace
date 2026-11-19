import { afterAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { closePool, makeApp, testConfig } from './helpers.js';

afterAll(closePool);

const failLogin = (app, xff) =>
  request(app).post('/api/auth/login').set('X-Forwarded-For', xff).send({ email: 'x@y.z', password: 'wrong-wrong' });

describe('behind two proxies (VPS nginx → web nginx)', () => {
  it('rate-limits each visitor separately', async () => {
    const { app } = makeApp({ config: testConfig({ TRUST_PROXY: '2' }) });
    // Each request arrives as "<visitor>, <vps nginx>" from the web container.
    for (let i = 0; i < 10; i++) await failLogin(app, '203.0.113.7, 172.18.0.1');
    expect((await failLogin(app, '203.0.113.7, 172.18.0.1')).status).toBe(429);
    expect((await failLogin(app, '198.51.100.9, 172.18.0.1')).status).toBe(401);
  });
});
