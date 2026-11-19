// Reset the demo data now (the same thing the 03:00 job does).
//   docker compose exec api node src/seed/reset-cli.js
import { loadConfig } from '../config.js';
import { createPool } from '../db/pool.js';
import { resetDemo } from './seed.js';

const config = loadConfig();
const pool = createPool(config.db);
try {
  await resetDemo(pool, { uploadDir: config.uploadDir });
  console.log('demo data reset');
} finally {
  await pool.end();
}
