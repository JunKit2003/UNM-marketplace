import http from 'node:http';
import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { createPool } from './db/pool.js';
import { migrate } from './db/migrate.js';
import { logger } from './logger.js';

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

const { app } = createApp({ pool, config });
const server = http.createServer(app);
server.listen(config.port, () => logger.info(`api listening on :${config.port}`));

for (const sig of ['SIGTERM', 'SIGINT']) {
  process.on(sig, () => {
    server.close(() => pool.end().finally(() => process.exit(0)));
  });
}
