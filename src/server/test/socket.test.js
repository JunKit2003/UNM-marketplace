import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { closePool, resetDb } from './helpers.js';
import { chatWorld, once } from './chatHelpers.js';

afterAll(closePool);
beforeEach(resetDb);
let world;
afterEach(async () => world?.close());

async function start() {
  world = await chatWorld();
  const conv = (await world.users.buyer.agent.post(`/api/listings/${world.listing.id}/conversations`)).body;
  const buyer = await world.socketFor(world.users.buyer.cookie);
  const seller = await world.socketFor(world.users.seller.cookie);
  return { ...world, conv, buyer, seller };
}

describe('chat socket', () => {
  it('rejects a connection without a session', async () => {
    world = await chatWorld();
    await expect(world.socketFor(null)).rejects.toThrow('unauthenticated');
  });

  it('delivers a sent message to the other participant within 2 seconds', async () => {
    const { conv, buyer, seller, users } = await start();
    const incoming = once(seller, 'message:new', 2000);
    const ack = await buyer.emitWithAck('message:send', { conversationId: conv.id, body: 'Still available?' });
    expect(ack.ok).toBe(true);
    expect(ack.message.body).toBe('Still available?');
    const evt = await incoming;
    expect(evt).toMatchObject({ conversationId: conv.id, message: { body: 'Still available?', senderId: users.buyer.id } });
  });

  it('also broadcasts messages sent over REST', async () => {
    const { conv, seller, users } = await start();
    const incoming = once(seller, 'message:new');
    await users.buyer.agent.post(`/api/conversations/${conv.id}/messages`).send({ body: 'via rest' });
    expect((await incoming).message.body).toBe('via rest');
  });

  it('relays typing only to the other participant', async () => {
    const { conv, buyer, seller, users, socketFor } = await start();
    const outsider = await socketFor(users.outsider.cookie);
    let outsiderSaw = false;
    outsider.on('typing', () => { outsiderSaw = true; });
    let buyerSaw = false;
    buyer.on('typing', () => { buyerSaw = true; });
    const typing = once(seller, 'typing');
    buyer.emit('typing', { conversationId: conv.id });
    expect(await typing).toEqual({ conversationId: conv.id, userId: users.buyer.id });
    await new Promise((r) => setTimeout(r, 150));
    expect(outsiderSaw).toBe(false);
    expect(buyerSaw).toBe(false);
  });

  it('refuses sends from a non-participant', async () => {
    const { conv, users, socketFor } = await start();
    const outsider = await socketFor(users.outsider.cookie);
    const ack = await outsider.emitWithAck('message:send', { conversationId: conv.id, body: 'sneaky' });
    expect(ack).toEqual({ ok: false, error: 'forbidden' });
  });

  it('tells the sender when the other person reads', async () => {
    const { conv, buyer, seller, users } = await start();
    await buyer.emitWithAck('message:send', { conversationId: conv.id, body: 'hi' });
    const read = once(buyer, 'conversation:read');
    seller.emit('conversation:read', { conversationId: conv.id });
    expect(await read).toEqual({ conversationId: conv.id, userId: users.seller.id });
  });

  it('shows the demo seller typing, then replying', async () => {
    const { conv, buyer, pool, users } = await start();
    await pool.query('UPDATE users SET is_seed = TRUE WHERE id = ?', [users.seller.id]);
    const typing = once(buyer, 'typing');
    const reply = new Promise((resolve) => {
      buyer.on('message:new', (e) => { if (e.message.senderId === users.seller.id) resolve(e); });
    });
    await buyer.emitWithAck('message:send', { conversationId: conv.id, body: 'where to meet?' });
    expect((await typing).userId).toBe(users.seller.id);
    expect((await reply).message.body).toMatch(/Trent Building/);
  });
});
