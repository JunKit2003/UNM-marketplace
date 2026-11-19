import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import { agent, closePool, makeApp, resetDb } from './helpers.js';
import { signupBody } from './fixtures.js';

afterAll(closePool);
beforeEach(resetDb);

describe('signup', () => {
  it('creates the account, logs in, and /auth/me returns it', async () => {
    const { app } = makeApp();
    const a = agent(app);
    const res = await a.post('/api/auth/signup').send(signupBody(1));
    expect(res.status).toBe(201);
    expect(res.headers['set-cookie'][0]).toMatch(/^unm\.sid=.*HttpOnly/);
    expect(res.body).toMatchObject({ username: 'amy1', displayName: 'Amy Tester1', isGuest: false, email: 'amy1@nottingham.edu.my' });
    expect(res.body).not.toHaveProperty('passwordHash');
    const me = await a.get('/api/auth/me');
    expect(me.status).toBe(200);
    expect(me.body.id).toBe(res.body.id);
  });

  it('rejects a duplicate email with the exact message', async () => {
    const { app } = makeApp();
    await request(app).post('/api/auth/signup').send(signupBody(1));
    const res = await request(app).post('/api/auth/signup').send(signupBody(2, { email: 'AMY1@nottingham.edu.my' }));
    expect(res.status).toBe(409);
    expect(res.body.error.message).toBe('That email is already registered.');
    expect(res.body.error.fields).toEqual({ email: 'That email is already registered.' });
  });

  it('rejects a duplicate username', async () => {
    const { app } = makeApp();
    await request(app).post('/api/auth/signup').send(signupBody(1));
    const res = await request(app).post('/api/auth/signup').send(signupBody(2, { username: 'Amy1' }));
    expect(res.status).toBe(409);
    expect(res.body.error.fields).toEqual({ username: 'That username is taken.' });
  });

  it('rejects a password shorter than 8 characters', async () => {
    const { app } = makeApp();
    const res = await request(app).post('/api/auth/signup').send(signupBody(1, { password: 'short' }));
    expect(res.status).toBe(400);
    expect(res.body.error.fields.password).toBeDefined();
  });
});

describe('login and logout', () => {
  it('logs in with the right password and out again', async () => {
    const { app } = makeApp();
    await request(app).post('/api/auth/signup').send(signupBody(1));
    const a = agent(app);
    const res = await a.post('/api/auth/login').send({ email: 'amy1@nottingham.edu.my', password: 'correct-horse-1' });
    expect(res.status).toBe(200);
    expect(res.body.username).toBe('amy1');
    expect((await a.post('/api/auth/logout')).status).toBe(204);
    expect((await a.get('/api/auth/me')).status).toBe(401);
  });

  it('uses one message for a wrong password and an unknown email', async () => {
    const { app } = makeApp();
    await request(app).post('/api/auth/signup').send(signupBody(1));
    const wrong = await request(app).post('/api/auth/login').send({ email: 'amy1@nottingham.edu.my', password: 'nope-nope-nope' });
    const unknown = await request(app).post('/api/auth/login').send({ email: 'ghost@nottingham.edu.my', password: 'nope-nope-nope' });
    for (const res of [wrong, unknown]) {
      expect(res.status).toBe(401);
      expect(res.body.error.message).toBe('Email or password is wrong.');
    }
  });

  it('refuses the 11th failed attempt within 15 minutes', async () => {
    const { app } = makeApp();
    for (let i = 0; i < 10; i++) {
      const r = await request(app).post('/api/auth/login').send({ email: 'x@y.z', password: 'wrong-wrong' });
      expect(r.status).toBe(401);
    }
    const res = await request(app).post('/api/auth/login').send({ email: 'x@y.z', password: 'wrong-wrong' });
    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe('rate_limited');
  });

  it('returns 401 from /auth/me when nobody is logged in', async () => {
    const { app } = makeApp();
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('unauthenticated');
  });
});

describe('demo guest login', () => {
  it('creates a distinct guest per click, even at the same moment', async () => {
    const { app } = makeApp();
    const [a, b] = await Promise.all([
      agent(app).post('/api/auth/demo'),
      agent(app).post('/api/auth/demo'),
    ]);
    for (const res of [a, b]) {
      expect(res.status).toBe(201);
      expect(res.body.isGuest).toBe(true);
      expect(res.body.displayName).toMatch(/^Guest \d{4}$/);
    }
    expect(a.body.id).not.toBe(b.body.id);
    expect(a.body.username).not.toBe(b.body.username);
  });

  it('keeps the guest logged in on later requests', async () => {
    const { app } = makeApp();
    const a = agent(app);
    const res = await a.post('/api/auth/demo');
    const me = await a.get('/api/auth/me');
    expect(me.status).toBe(200);
    expect(me.body.isGuest).toBe(true);
    expect(me.body.id).toBe(res.body.id);
  });

  it('runs the onGuestCreated hook for starter content', async () => {
    const seen = [];
    const { app } = makeApp({ hooks: { onGuestCreated: async (u) => seen.push(u.id) } });
    const res = await agent(app).post('/api/auth/demo');
    expect(seen).toEqual([res.body.id]);
  });
});
