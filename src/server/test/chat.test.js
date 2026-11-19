import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { closePool, resetDb } from './helpers.js';
import { chatWorld, eventually } from './chatHelpers.js';

afterAll(closePool);
beforeEach(resetDb);
let world;
afterEach(async () => world?.close());

async function start() {
  world = await chatWorld();
  const { users, listing } = world;
  const conv = await users.buyer.agent.post(`/api/listings/${listing.id}/conversations`);
  return { ...world, conv };
}

describe('starting a conversation', () => {
  it('creates it once and reuses it', async () => {
    const { users, listing, conv } = await start();
    expect(conv.status).toBe(201);
    expect(conv.body).toMatchObject({
      listing: { id: listing.id, title: 'Desk lamp', price: 45, status: 'active' },
      otherUser: { id: users.seller.id, displayName: 'Amy Tester1' },
      lastMessage: null,
      unreadCount: 0,
    });
    expect(conv.body.listing.coverUrl).toBe(listing.coverUrl);
    const again = await users.buyer.agent.post(`/api/listings/${listing.id}/conversations`);
    expect(again.status).toBe(200);
    expect(again.body.id).toBe(conv.body.id);
  });

  it('refuses the owner messaging themselves', async () => {
    const { users, listing } = await start();
    const res = await users.seller.agent.post(`/api/listings/${listing.id}/conversations`);
    expect(res.status).toBe(403);
    expect(res.body.error.message).toBe("You can't message yourself about your own listing.");
  });

  it('refuses a sold listing', async () => {
    world = await chatWorld();
    const { users, listing } = world;
    await users.seller.agent.patch(`/api/listings/${listing.id}`).send({ status: 'sold' });
    const res = await users.buyer.agent.post(`/api/listings/${listing.id}/conversations`);
    expect(res.status).toBe(409);
    expect(res.body.error.message).toBe('This item has been sold.');
  });

  it('returns 404 for an unknown listing', async () => {
    world = await chatWorld();
    expect((await world.users.buyer.agent.post('/api/listings/999999/conversations')).status).toBe(404);
  });
});

describe('messages over REST', () => {
  it('sends, lists, counts unread and marks read', async () => {
    const { users, conv } = await start();
    const id = conv.body.id;
    const sent = await users.buyer.agent.post(`/api/conversations/${id}/messages`).send({ body: 'Still available?' });
    expect(sent.status).toBe(201);
    expect(sent.body).toMatchObject({ conversationId: id, senderId: users.buyer.id, body: 'Still available?', readAt: null });

    expect((await users.seller.agent.get('/api/me/unread')).body).toEqual({ count: 1 });
    expect((await users.buyer.agent.get('/api/me/unread')).body).toEqual({ count: 0 });
    const inbox = await users.seller.agent.get('/api/conversations');
    expect(inbox.body[0]).toMatchObject({ id, unreadCount: 1, otherUser: { id: users.buyer.id }, lastMessage: { body: 'Still available?' } });

    expect((await users.seller.agent.post(`/api/conversations/${id}/read`)).status).toBe(204);
    expect((await users.seller.agent.get('/api/me/unread')).body).toEqual({ count: 0 });
    const msgs = await users.buyer.agent.get(`/api/conversations/${id}/messages`);
    expect(msgs.body[0].readAt).not.toBeNull();
  });

  it('returns a single conversation for a participant', async () => {
    const { users, conv } = await start();
    const res = await users.seller.agent.get(`/api/conversations/${conv.body.id}`);
    expect(res.status).toBe(200);
    expect(res.body.otherUser.id).toBe(users.buyer.id);
  });

  it('pages history with before, oldest to newest', async () => {
    const { users, conv } = await start();
    const id = conv.body.id;
    const ids = [];
    for (let i = 1; i <= 5; i++) {
      ids.push((await users.buyer.agent.post(`/api/conversations/${id}/messages`).send({ body: `m${i}` })).body.id);
    }
    const latest = await users.buyer.agent.get(`/api/conversations/${id}/messages?limit=2`);
    expect(latest.body.map((m) => m.body)).toEqual(['m4', 'm5']);
    const older = await users.buyer.agent.get(`/api/conversations/${id}/messages?limit=2&before=${ids[3]}`);
    expect(older.body.map((m) => m.body)).toEqual(['m2', 'm3']);
  });

  it('orders the inbox by latest message', async () => {
    world = await chatWorld();
    const { users, listing } = world;
    const { postListing } = await import('./fixtures.js');
    const second = (await postListing(users.seller.agent, { title: 'Rice cooker' })).body;
    const c1 = (await users.buyer.agent.post(`/api/listings/${listing.id}/conversations`)).body;
    const c2 = (await users.buyer.agent.post(`/api/listings/${second.id}/conversations`)).body;
    await users.buyer.agent.post(`/api/conversations/${c2.id}/messages`).send({ body: 'first' });
    await new Promise((r) => setTimeout(r, 10));
    await users.buyer.agent.post(`/api/conversations/${c1.id}/messages`).send({ body: 'second' });
    const inbox = await users.buyer.agent.get('/api/conversations');
    expect(inbox.body.map((c) => c.id)).toEqual([c1.id, c2.id]);
  });

  it.each([[''], ['   '], ['x'.repeat(2001)]])('rejects body %#', async (body) => {
    const { users, conv } = await start();
    const res = await users.buyer.agent.post(`/api/conversations/${conv.body.id}/messages`).send({ body });
    expect(res.status).toBe(400);
  });

  it('keeps outsiders out', async () => {
    const { users, conv } = await start();
    const id = conv.body.id;
    expect((await users.outsider.agent.get(`/api/conversations/${id}/messages`)).status).toBe(403);
    expect((await users.outsider.agent.get(`/api/conversations/${id}`)).status).toBe(403);
    expect((await users.outsider.agent.post(`/api/conversations/${id}/messages`).send({ body: 'hi' })).status).toBe(403);
    expect((await users.outsider.agent.post(`/api/conversations/${id}/read`)).status).toBe(403);
  });

  it('removes the conversation from both inboxes when the listing is deleted', async () => {
    const { users, listing, conv } = await start();
    await users.buyer.agent.post(`/api/conversations/${conv.body.id}/messages`).send({ body: 'hi' });
    await users.seller.agent.delete(`/api/listings/${listing.id}`);
    expect((await users.buyer.agent.get('/api/conversations')).body).toEqual([]);
    expect((await users.seller.agent.get('/api/conversations')).body).toEqual([]);
    expect((await users.buyer.agent.get(`/api/conversations/${conv.body.id}`)).status).toBe(404);
    expect((await users.buyer.agent.get('/api/me/unread')).body).toEqual({ count: 0 });
  });
});

describe('demo seller', () => {
  it('replies about the listing when a seed seller is messaged', async () => {
    const { users, conv, pool } = await start();
    await pool.query('UPDATE users SET is_seed = TRUE WHERE id = ?', [users.seller.id]);
    await users.buyer.agent.post(`/api/conversations/${conv.body.id}/messages`).send({ body: 'Is it still available?' });
    const msgs = await eventually(async () => {
      const r = await users.buyer.agent.get(`/api/conversations/${conv.body.id}/messages`);
      if (r.body.length < 2) throw new Error('no reply yet');
      return r.body;
    });
    expect(msgs[1].senderId).toBe(users.seller.id);
    expect(msgs[1].body).toBe('Hi! Yes, the Desk lamp is still available 🙂');
  });

  it('does not auto-reply for real sellers', async () => {
    const { users, conv } = await start();
    await users.buyer.agent.post(`/api/conversations/${conv.body.id}/messages`).send({ body: 'Is it still available?' });
    await new Promise((r) => setTimeout(r, 200));
    const r = await users.buyer.agent.get(`/api/conversations/${conv.body.id}/messages`);
    expect(r.body).toHaveLength(1);
  });
});
