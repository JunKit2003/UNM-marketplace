import express from 'express';
import session from 'express-session';
import MySQLStoreFactory from 'express-mysql-session';
import helmet from 'helmet';
import path from 'node:path';
import { errorHandler, notFoundHandler } from './http/errors.js';

const MySQLStore = MySQLStoreFactory(session);

/**
 * Build the Express app. Feature routers register themselves through `routes`.
 * Returns the app plus the session middleware so Socket.IO can share sessions.
 */
export function createApp({ pool, config, sessionStore, routes = defaultRoutes } = {}) {
  const app = express();
  app.disable('x-powered-by');
  if (config.trustProxy) app.set('trust proxy', 1);
  app.locals.pool = pool;
  app.locals.config = config;

  app.use(helmet({ contentSecurityPolicy: false, crossOriginResourcePolicy: { policy: 'same-origin' } }));
  app.use(express.json({ limit: '100kb' }));

  const store = sessionStore === 'memory' || !pool?.getConnection
    ? new session.MemoryStore()
    : new MySQLStore({ createDatabaseTable: true, clearExpired: true, expiration: 30 * 24 * 3600 * 1000 }, pool);

  const sessionMiddleware = session({
    name: 'unm.sid',
    secret: config.sessionSecret,
    store,
    resave: false,
    saveUninitialized: false,
    rolling: true,
    cookie: {
      httpOnly: true,
      sameSite: 'lax',
      secure: config.isProduction,
      maxAge: 30 * 24 * 3600 * 1000,
    },
  });
  app.use('/api', sessionMiddleware);

  const api = express.Router();
  api.get('/health', async (req, res) => {
    try {
      await pool.query('SELECT 1');
      res.json({ ok: true });
    } catch {
      res.status(503).json({ ok: false });
    }
  });
  for (const register of routes) register(api, { pool, config });
  api.use(notFoundHandler);
  app.use('/api', api);

  // Uploaded photos. In production nginx proxies /images here too.
  app.use('/images', express.static(path.resolve(config.uploadDir), { maxAge: '7d', fallthrough: false }));

  app.use(errorHandler);
  return { app, sessionMiddleware, store };
}

// Feature modules append to this list (see src/routes.js).
const defaultRoutes = [];
export { defaultRoutes };
