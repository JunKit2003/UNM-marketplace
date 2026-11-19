import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import fs from 'node:fs/promises';
import path from 'node:path';
import request from 'supertest';
import { agent, closePool, makeApp, resetDb, tempUploadDir, testConfig } from './helpers.js';
import { notAnImage, pngBuffer, signupBody } from './fixtures.js';

afterAll(closePool);
beforeEach(resetDb);

async function signedUp(app, n = 1) {
  const a = agent(app);
  await a.post('/api/auth/signup').send(signupBody(n));
  return a;
}

describe('profile', () => {
  it('updates name and phone', async () => {
    const { app } = makeApp();
    const a = await signedUp(app);
    const res = await a.patch('/api/me').send({ firstName: 'Amelia', phone: '+60 11-111 1111' });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ firstName: 'Amelia', displayName: 'Amelia Tester1', phone: '+60 11-111 1111' });
  });

  it('requires login', async () => {
    const { app } = makeApp();
    expect((await request(app).patch('/api/me').send({ firstName: 'X' })).status).toBe(401);
  });
});

describe('change password', () => {
  it('changes it when the current password is right', async () => {
    const { app } = makeApp();
    const a = await signedUp(app);
    const res = await a.put('/api/me/password').send({ currentPassword: 'correct-horse-1', newPassword: 'battery-staple-2' });
    expect(res.status).toBe(204);
    const login = await request(app).post('/api/auth/login').send({ email: 'amy1@nottingham.edu.my', password: 'battery-staple-2' });
    expect(login.status).toBe(200);
  });

  it('keeps the old password when the current one is wrong', async () => {
    const { app } = makeApp();
    const a = await signedUp(app);
    const res = await a.put('/api/me/password').send({ currentPassword: 'not-it-at-all', newPassword: 'battery-staple-2' });
    expect(res.status).toBe(400);
    expect(res.body.error.fields).toEqual({ currentPassword: 'Your current password is wrong.' });
    const login = await request(app).post('/api/auth/login').send({ email: 'amy1@nottingham.edu.my', password: 'correct-horse-1' });
    expect(login.status).toBe(200);
  });

  it('is forbidden for guests', async () => {
    const { app } = makeApp();
    const a = agent(app);
    await a.post('/api/auth/demo');
    const res = await a.put('/api/me/password').send({ currentPassword: 'whatever-1', newPassword: 'battery-staple-2' });
    expect(res.status).toBe(403);
  });
});

describe('profile photo', () => {
  it('stores a PNG as a WebP avatar and serves it', async () => {
    const dir = await tempUploadDir();
    const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir }) });
    const a = await signedUp(app);
    const res = await a.put('/api/me/photo').attach('photo', await pngBuffer(900, 700), 'me.png');
    expect(res.status).toBe(200);
    expect(res.body.avatarUrl).toMatch(/^\/images\/avatars\/[a-f0-9-]+\.webp$/);
    const file = path.join(dir, res.body.avatarUrl.replace('/images/', ''));
    const meta = await (await import('sharp')).default(await fs.readFile(file)).metadata();
    expect(meta.format).toBe('webp');
    expect(Math.max(meta.width, meta.height)).toBeLessThanOrEqual(512);
    const served = await request(app).get(res.body.avatarUrl);
    expect(served.status).toBe(200);
  });

  it('rejects a text file renamed to .jpg with the photo message', async () => {
    const dir = await tempUploadDir();
    const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir }) });
    const a = await signedUp(app);
    const res = await a.put('/api/me/photo').attach('photo', notAnImage, { filename: 'x.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(400);
    expect(res.body.error.message).toBe('Photos must be JPEG, PNG or WebP, up to 5 MB.');
  });

  it('removes the previous avatar file when replaced', async () => {
    const dir = await tempUploadDir();
    const { app } = makeApp({ config: testConfig({ UPLOAD_DIR: dir }) });
    const a = await signedUp(app);
    const first = await a.put('/api/me/photo').attach('photo', await pngBuffer(), 'a.png');
    await a.put('/api/me/photo').attach('photo', await pngBuffer(), 'b.png');
    const oldFile = path.join(dir, first.body.avatarUrl.replace('/images/', ''));
    await expect(fs.access(oldFile)).rejects.toThrow();
  });
});
