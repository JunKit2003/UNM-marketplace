import { HttpError, notFound } from '../../http/errors.js';
import { logger } from '../../logger.js';
import { findListingRow } from '../listings/repo.js';
import { findUserById } from '../users/repo.js';
import { pickReply } from './demoSeller.js';
import * as repo from './repo.js';
import { serializeConversation, serializeMessage } from './serialize.js';

export const CONVERSATION_GONE = 'This listing was removed.';

/**
 * Chat use-cases shared by REST routes and the socket. Broadcasting goes through an
 * emitter set by attachSocket; without one (tests, scripts) it is a no-op.
 */
export function createChatService({ pool, config }) {
  let io = null;
  const pending = new Set();
  const emitTo = (userIds, event, payload) => {
    if (!io) return;
    for (const id of new Set(userIds)) io.to(`user:${id}`).emit(event, payload);
  };

  async function participantConversation(conversationId, userId) {
    const row = Number.isInteger(conversationId) ? await repo.findConversationRow(pool, conversationId) : null;
    if (!row) throw notFound(CONVERSATION_GONE);
    if (row.buyer_id !== userId && row.seller_id !== userId) throw new HttpError(403, 'forbidden', "You're not part of this chat.");
    return row;
  }

  async function getConversation(conversationId, userId) {
    await participantConversation(conversationId, userId);
    const [row] = await repo.conversationsFor(pool, userId, conversationId);
    return serializeConversation(row);
  }

  async function startConversation(listingId, buyerId) {
    const listing = await findListingRow(pool, listingId);
    if (!listing) throw notFound("This listing doesn't exist or was removed.");
    if (listing.seller_id === buyerId) throw new HttpError(403, 'forbidden', "You can't message yourself about your own listing.");
    const existing = await repo.findConversationByListingBuyer(pool, listingId, buyerId);
    if (existing) return { conversation: await getConversation(existing.id, buyerId), created: false };
    if (listing.status === 'sold') throw new HttpError(409, 'conflict', 'This item has been sold.');
    const { row, created } = await repo.insertConversation(pool, listingId, buyerId, listing.seller_id);
    return { conversation: await getConversation(row.id, buyerId), created };
  }

  /** A conversation the seller opened (guest starter content). */
  async function startSeededConversation(listingId, buyerId, sellerOpeningBody) {
    const listing = await findListingRow(pool, listingId);
    const { row } = await repo.insertConversation(pool, listingId, buyerId, listing.seller_id);
    await repo.insertMessage(pool, row.id, listing.seller_id, sellerOpeningBody);
    return row;
  }

  async function sendMessage({ conversationId, senderId, body }) {
    const conv = await participantConversation(conversationId, senderId);
    const listing = await findListingRow(pool, conv.listing_id);
    const message = serializeMessage(await repo.insertMessage(pool, conv.id, senderId, body));
    emitTo([conv.buyer_id, conv.seller_id], 'message:new', { conversationId: conv.id, message });
    maybeDemoReply(conv, senderId, listing, body);
    return message;
  }

  function typing(conv, userId) {
    const other = conv.buyer_id === userId ? conv.seller_id : conv.buyer_id;
    emitTo([other], 'typing', { conversationId: conv.id, userId });
  }

  async function markRead(conversationId, userId) {
    const conv = await participantConversation(conversationId, userId);
    await repo.markRead(pool, conv.id, userId);
    const other = conv.buyer_id === userId ? conv.seller_id : conv.buyer_id;
    emitTo([other], 'conversation:read', { conversationId: conv.id, userId });
  }

  function maybeDemoReply(conv, senderId, listing, body) {
    const recipientId = conv.buyer_id === senderId ? conv.seller_id : conv.buyer_id;
    const task = (async () => {
      const [recipient, sender] = await Promise.all([findUserById(pool, recipientId), findUserById(pool, senderId)]);
      if (!recipient?.is_seed || sender?.is_seed) return;
      const delay = config.demoReplyDelayMs;
      await new Promise((r) => setTimeout(r, Math.round(delay * 0.4)));
      typing(conv, recipientId);
      await new Promise((r) => setTimeout(r, Math.round(delay * 0.6)));
      await sendMessage({ conversationId: conv.id, senderId: recipientId, body: pickReply(listing.title, body) });
    })().catch((err) => {
      // The conversation may be gone (listing deleted, nightly reset) by the time we reply.
      if (!(err instanceof HttpError)) logger.warn({ err }, 'demo reply failed');
    });
    pending.add(task);
    task.finally(() => pending.delete(task));
  }

  return {
    setEmitter: (server) => { io = server; },
    participantConversation,
    getConversation,
    startConversation,
    startSeededConversation,
    sendMessage,
    typing,
    markRead,
    list: async (userId) => (await repo.conversationsFor(pool, userId)).map(serializeConversation),
    messages: async (conversationId, userId, opts) => {
      await participantConversation(conversationId, userId);
      return (await repo.messagesFor(pool, conversationId, opts)).map(serializeMessage);
    },
    unread: (userId) => repo.unreadTotal(pool, userId),
    /** Wait for in-flight demo replies (tests and shutdown). */
    settle: () => Promise.allSettled([...pending]),
  };
}
