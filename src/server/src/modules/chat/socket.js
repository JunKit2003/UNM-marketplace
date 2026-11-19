import { Server } from 'socket.io';
import { HttpError } from '../../http/errors.js';
import { logger } from '../../logger.js';
import { messageBody } from './routes.js';

const MESSAGES_PER_MINUTE = 60;

/**
 * Socket.IO on the same HTTP server, sharing the Express session. Each socket joins
 * `user:<id>` so the chat service can reach every tab a user has open.
 */
/**
 * Only same-origin browsers may open a socket (blocks cross-site WebSocket hijacking).
 * Requests without an Origin header (non-browser clients) still need a valid session.
 */
export function sameOrigin(req) {
  const origin = req.headers.origin;
  if (!origin) return true;
  const host = req.headers['x-forwarded-host'] ?? req.headers.host;
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}

export function attachSocket(httpServer, { sessionMiddleware, chat }) {
  const io = new Server(httpServer, {
    path: '/socket.io',
    serveClient: false,
    allowRequest: (req, cb) => cb(null, sameOrigin(req)),
  });
  io.engine.use(sessionMiddleware);

  io.use((socket, next) => {
    const userId = socket.request.session?.userId;
    if (!userId) return next(new Error('unauthenticated'));
    socket.data.userId = userId;
    next();
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId;
    socket.join(`user:${userId}`);
    let windowStart = Date.now();
    let sent = 0;

    const safe = (handler) => async (payload, ack) => {
      try {
        const result = await handler(payload ?? {});
        if (typeof ack === 'function') ack({ ok: true, ...result });
      } catch (err) {
        if (!(err instanceof HttpError)) logger.warn({ err }, 'socket handler failed');
        if (typeof ack === 'function') ack({ ok: false, error: err instanceof HttpError ? err.code : 'internal' });
      }
    };

    socket.on('message:send', safe(async ({ conversationId, body }) => {
      if (Date.now() - windowStart > 60_000) {
        windowStart = Date.now();
        sent = 0;
      }
      if (++sent > MESSAGES_PER_MINUTE) throw new HttpError(429, 'rate_limited', 'Too fast.');
      const parsed = messageBody.safeParse({ body });
      if (!parsed.success) throw new HttpError(400, 'validation', 'Invalid message.');
      const message = await chat.sendMessage({ conversationId: Number(conversationId), senderId: userId, body: parsed.data.body });
      return { message };
    }));

    socket.on('typing', safe(async ({ conversationId }) => {
      const conv = await chat.participantConversation(Number(conversationId), userId);
      chat.typing(conv, userId);
      return {};
    }));

    socket.on('conversation:read', safe(async ({ conversationId }) => {
      await chat.markRead(Number(conversationId), userId);
      return {};
    }));
  });

  chat.setEmitter(io);
  return io;
}
