import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { createPool } from '../src/db/pool.js';
import { testDbConfig } from './dbConfig.js';

let pool;
export function getPool() {
  // Same options as production (UTC, utf8mb4) so date handling matches.
  pool ??= createPool(testDbConfig());
  return pool;
}

export async function closePool() {
  if (pool) await pool.end();
  pool = undefined;
}

export async function tempUploadDir() {
  return fs.mkdtemp(path.join(os.tmpdir(), 'unm-uploads-'));
}

export function testConfig(overrides = {}) {
  const db = testDbConfig();
  return loadConfig({
    NODE_ENV: 'test',
    DB_HOST: db.host,
    DB_PORT: String(db.port),
    DB_USER: db.user,
    DB_PASSWORD: db.password,
    DB_NAME: db.database,
    SESSION_SECRET: 'test-secret-test-secret-test-secret-123',
    UPLOAD_DIR: overrides.UPLOAD_DIR ?? path.join(os.tmpdir(), 'unm-test-uploads'),
    SEED_DEMO: 'false',
    DEMO_REPLY_DELAY_MS: '0',
    BCRYPT_COST: '4',
    ...overrides,
  });
}

export function makeApp({ pool: p = getPool(), config = testConfig(), ...rest } = {}) {
  return createApp({ pool: p, config, ...rest });
}

// Empty every application table (keeps categories, which migrations seed).
export async function resetDb() {
  const p = getPool();
  const [rows] = await p.query(
    `SELECT table_name AS t FROM information_schema.tables
     WHERE table_schema = DATABASE() AND table_name NOT IN ('schema_migrations','categories')`,
  );
  await p.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const { t } of rows) await p.query(`TRUNCATE TABLE \`${t}\``);
  await p.query('SET FOREIGN_KEY_CHECKS = 1');
}

export function agent(app) {
  return request.agent(app);
}
