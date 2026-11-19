import { z } from 'zod';
import { requireUser } from '../../http/auth.js';
import { validate } from '../../http/validate.js';
import { notFound } from '../../http/errors.js';
import { parseId } from '../listings/routes.js';

export const messageBody = z.object({
  body: z.string().trim().min(1, 'Write a message first.').max(2000, 'Keep messages under 2,000 characters.'),
});

const historyQuery = z.object({
  before: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(50),
});

export function registerChat(api, { services, limits }) {
  const chat = services.chat;
  const convId = (req) => parseId(req.params.id) ?? -1;

  api.get('/conversations', requireUser, async (req, res) => {
    res.json(await chat.list(req.session.userId));
  });

  api.get('/me/unread', requireUser, async (req, res) => {
    res.json({ count: await chat.unread(req.session.userId) });
  });

  api.post('/listings/:id/conversations', requireUser, async (req, res) => {
    const id = parseId(req.params.id);
    if (!id) throw notFound("This listing doesn't exist or was removed.");
    const { conversation, created } = await chat.startConversation(id, req.session.userId);
    res.status(created ? 201 : 200).json(conversation);
  });

  api.get('/conversations/:id', requireUser, async (req, res) => {
    res.json(await chat.getConversation(convId(req), req.session.userId));
  });

  api.get('/conversations/:id/messages', requireUser, validate(historyQuery, 'query'), async (req, res) => {
    res.json(await chat.messages(convId(req), req.session.userId, req.valid.query));
  });

  api.post('/conversations/:id/messages', requireUser, limits.messages, validate(messageBody), async (req, res) => {
    const message = await chat.sendMessage({ conversationId: convId(req), senderId: req.session.userId, body: req.valid.body.body });
    res.status(201).json(message);
  });

  api.post('/conversations/:id/read', requireUser, async (req, res) => {
    await chat.markRead(convId(req), req.session.userId);
    res.status(204).end();
  });
}
