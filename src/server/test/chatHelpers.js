import http from 'node:http';
import { io as connect } from 'socket.io-client';
import { agent, getPool, makeApp, tempUploadDir, testConfig } from './helpers.js';
import { postListing, signupBody } from './fixtures.js';
import { attachSocket } from '../src/modules/chat/socket.js';

/** App + listening HTTP server with Socket.IO, plus buyer/seller/outsider agents and one listing. */
export async function chatWorld({ configOverrides = {} } = {}) {
  const config = testConfig({ UPLOAD_DIR: await tempUploadDir(), ...configOverrides });
  const built = makeApp({ config });
  const server = http.createServer(built.app);
  const io = attachSocket(server, { sessionMiddleware: built.sessionMiddleware, chat: built.services.chat });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;

  const users = {};
  for (const [name, n] of [['seller', 1], ['buyer', 2], ['outsider', 3]]) {
    const a = agent(server);
    const res = await a.post('/api/auth/signup').send(signupBody(n));
    users[name] = { agent: a, id: res.body.id, cookie: res.headers['set-cookie'][0].split(';')[0] };
  }
  const listing = (await postListing(users.seller.agent, { title: 'Desk lamp' })).body;

  const sockets = [];
  const socketFor = (cookie, extra = {}) =>
    new Promise((resolve, reject) => {
      const headers = { ...(cookie ? { cookie } : {}), ...extra };
      const s = connect(base, { transports: ['websocket'], extraHeaders: headers, reconnection: false });
      sockets.push(s);
      s.on('connect', () => resolve(s));
      s.on('connect_error', reject);
    });

  const close = async () => {
    for (const s of sockets) s.disconnect();
    io.close();
    await new Promise((r) => server.close(r));
  };
  return { app: built.app, server, base, users, listing, socketFor, close, pool: getPool(), chat: built.services.chat };
}

export const once = (socket, event, ms = 2000) =>
  new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error(`timed out waiting for ${event}`)), ms);
    socket.once(event, (payload) => {
      clearTimeout(t);
      resolve(payload);
    });
  });

export async function eventually(fn, ms = 3000) {
  const end = Date.now() + ms;
  for (;;) {
    try {
      return await fn();
    } catch (err) {
      if (Date.now() > end) throw err;
      await new Promise((r) => setTimeout(r, 50));
    }
  }
}
