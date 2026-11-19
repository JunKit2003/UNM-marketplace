import mysql from 'mysql2/promise';
import { testDbConfig } from '../dbConfig.js';
import { migrate } from '../../src/db/migrate.js';

// Rebuild the test database from the migrations once per run.
export default async function setup() {
  const cfg = testDbConfig();
  const admin = await mysql.createConnection({ ...cfg, database: undefined, multipleStatements: true });
  await admin.query(`DROP DATABASE IF EXISTS \`${cfg.database}\``);
  await admin.query(`CREATE DATABASE \`${cfg.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
  await admin.end();
  const pool = mysql.createPool({ ...cfg, multipleStatements: true });
  await migrate(pool);
  await pool.end();
}
