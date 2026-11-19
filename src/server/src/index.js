import http from 'node:http';
import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { createPool } from './db/pool.js';
import { migrate } from './db/migrate.js';
import { logger } from './logger.js';
import cron from 'node-cron';
import { attachSocket } from './modules/chat/socket.js';
import { resetDemo, seedDemo } from './seed/seed.js';

const config = loadConfig();
const pool = createPool(config.db);

async function waitForDb(retries = 30) {
  for (let i = 1; ; i++) {
    try {
      await pool.query('SELECT 1');
      return;
    } catch (err) {
      if (i >= retries) throw err;
      logger.warn(`database not ready (attempt ${i}), retrying`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
}

await waitForDb();
const ran = await migrate(pool);
if (ran.length) logger.info({ ran }, 'migrations applied');
if (config.seedDemo) await seedDemo(pool, { uploadDir: config.uploadDir });

const { app, sessionMiddleware, services } = createApp({ pool, config });
const server = http.createServer(app);
const io = attachSocket(server, { sessionMiddleware, chat: services.chat });
server.listen(config.port, () => logger.info(`api listening on :${config.port}`));

if (config.seedDemo) {
  // Showcase mode: wipe visitor data every night at 03:00 Malaysia time.
  cron.schedule('0 3 * * *', async () => {
    try {
      io.disconnectSockets(true);
      await resetDemo(pool, { uploadDir: config.uploadDir });
    } catch (err) {
      logger.error({ err }, 'demo reset failed');
    }
  }, { timezone: 'Asia/Kuala_Lumpur' });
}

for (const sig of ['SIGTERM', 'SIGINT']) {
  process.on(sig, () => {
    io.close();
    server.close(() => pool.end().finally(() => process.exit(0)));
  });
}
