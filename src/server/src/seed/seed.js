import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { logger } from '../logger.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const read = async (f) => JSON.parse(await fs.readFile(path.join(here, 'data', f), 'utf8'));
const SOURCE_IMAGES = path.join(here, 'images');
const HOUR = 3600_000;

function avatarSvg(initials, [from, to]) {
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs>
    <rect width="256" height="256" fill="url(#g)"/>
    <text x="128" y="150" text-anchor="middle" font-family="sans-serif" font-size="96" font-weight="700" fill="#fff">${initials}</text>
  </svg>`);
}

/** Gradient placeholder if a seed photo is missing, so the demo never shows a broken image. */
function placeholder(label) {
  return sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="900">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#10263B"/><stop offset="1" stop-color="#7C5CFF"/></linearGradient></defs>
    <rect width="1200" height="900" fill="url(#g)"/>
    <text x="600" y="470" text-anchor="middle" font-family="sans-serif" font-size="64" fill="#fff">${label.replace(/[<&>"]/g, '')}</text>
  </svg>`)).webp({ quality: 80 }).toBuffer();
}

async function writeFile(uploadDir, rel, buffer) {
  const abs = path.join(uploadDir, rel);
  await fs.mkdir(path.dirname(abs), { recursive: true });
  await fs.writeFile(abs, buffer);
}

/** Insert the demo sellers and listings. Returns false (and does nothing) if they already exist. */
export async function seedDemo(pool, { uploadDir }) {
  const [[{ n }]] = await pool.query('SELECT COUNT(*) AS n FROM users WHERE is_seed');
  if (Number(n) > 0) return false;
  const users = await read('users.json');
  const listings = await read('listings.json');
  const [cats] = await pool.query('SELECT id, slug FROM categories');
  const catId = Object.fromEntries(cats.map((c) => [c.slug, c.id]));

  const userId = {};
  for (const u of users) {
    const rel = `seed/avatars/${u.username}.webp`;
    const initials = `${u.firstName[0]}${u.lastName[0]}`;
    await writeFile(uploadDir, rel, await sharp(avatarSvg(initials, u.colors)).webp({ quality: 85 }).toBuffer());
    const [res] = await pool.query(
      `INSERT INTO users (username, first_name, last_name, avatar_path, is_seed, created_at)
       VALUES (?, ?, ?, ?, TRUE, NOW(3) - INTERVAL 30 DAY)`,
      [u.username, u.firstName, u.lastName, rel],
    );
    userId[u.username] = res.insertId;
  }

  const now = Date.now();
  for (const [i, l] of listings.entries()) {
    // Newest first in file order, spread over ~13 days.
    const created = new Date(now - (i * 10.7 + 1) * HOUR);
    const [res] = await pool.query(
      `INSERT INTO listings (seller_id, category_id, title, description, price, \`condition\`, status, is_seed, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, ?, ?)`,
      [userId[l.seller], catId[l.category], l.title, l.description, l.price, l.condition, l.status ?? 'active', created, created],
    );
    const rel = `seed/listings/${l.slug}.webp`;
    const source = await fs.readFile(path.join(SOURCE_IMAGES, `${l.slug}.webp`)).catch(() => null);
    if (!source) logger.warn(`seed photo missing for ${l.slug}, using placeholder`);
    await writeFile(uploadDir, rel, source ?? (await placeholder(l.title)));
    await pool.query('INSERT INTO listing_images (listing_id, path, position) VALUES (?, ?, 0)', [res.insertId, rel]);
  }
  logger.info(`seeded ${users.length} demo users and ${listings.length} listings`);
  return true;
}

/** Nightly reset: drop everything (accounts, listings, chats, sessions, uploads) and re-seed. */
export async function resetDemo(pool, { uploadDir }) {
  const [tables] = await pool.query(
    `SELECT table_name AS t FROM information_schema.tables
     WHERE table_schema = DATABASE() AND table_name NOT IN ('schema_migrations', 'categories')`,
  );
  const conn = await pool.getConnection();
  try {
    await conn.query('SET FOREIGN_KEY_CHECKS = 0');
    for (const { t } of tables) await conn.query(`TRUNCATE TABLE \`${t}\``);
    await conn.query('SET FOREIGN_KEY_CHECKS = 1');
  } finally {
    conn.release();
  }
  for (const dir of ['listings', 'avatars', 'seed']) {
    await fs.rm(path.join(uploadDir, dir), { recursive: true, force: true });
  }
  await seedDemo(pool, { uploadDir });
  logger.info('demo data reset');
}

const lowerFirst = (t) => (/^[A-Z][a-z]/.test(t) ? t[0].toLowerCase() + t.slice(1) : t);

/** A new guest gets one saved listing and one chat a demo seller already started. */
export async function giveGuestStarterContent(pool, chat, guest) {
  const [rows] = await pool.query(
    "SELECT id, title FROM listings WHERE is_seed AND status = 'active' ORDER BY RAND() LIMIT 2",
  );
  if (rows.length < 2) return;
  const [toSave, toChat] = rows;
  await pool.query('INSERT IGNORE INTO saved_listings (user_id, listing_id) VALUES (?, ?)', [guest.id, toSave.id]);
  await chat.startSeededConversation(
    toChat.id,
    guest.id,
    `Hey! Saw you checking out my ${lowerFirst(toChat.title)}. Any questions, just ask 😊`,
  );
}
