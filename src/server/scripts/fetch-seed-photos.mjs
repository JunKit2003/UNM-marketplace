#!/usr/bin/env node
// Dev-only helper: fetch one openly licensed photo per seed listing from Openverse,
// save it as 1600 px WebP under src/seed/images/ and record credits.
// Not run in CI or Docker; the results are committed.
//
//   node scripts/fetch-seed-photos.mjs                 # fetch missing photos
//   node scripts/fetch-seed-photos.mjs desk-lamp=2     # re-pick result #2 for a slug
//   node scripts/fetch-seed-photos.mjs --sheet         # write a contact sheet to /tmp
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const here = path.dirname(fileURLToPath(import.meta.url));
const seedDir = path.resolve(here, '../src/seed');
const imagesDir = path.join(seedDir, 'images');
const creditsFile = path.join(seedDir, 'data/credits.json');
const listings = JSON.parse(await fs.readFile(path.join(seedDir, 'data/listings.json'), 'utf8'));
const credits = JSON.parse(await fs.readFile(creditsFile, 'utf8').catch(() => '{}'));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const args = process.argv.slice(2);
const picks = Object.fromEntries(args.filter((a) => a.includes('=')).map((a) => a.split('=')).map(([k, v]) => [k, Number(v)]));

async function search(query) {
  const url = new URL('https://api.openverse.org/v1/images/');
  url.search = new URLSearchParams({
    q: query,
    license: 'cc0,pdm,by,by-sa',
    page_size: '12',
    mature: 'false',
  });
  for (let attempt = 1; attempt <= 5; attempt++) {
    const res = await fetch(url, { headers: { 'User-Agent': 'unm-marketplace-seed/1.0' } });
    if (res.ok) return (await res.json()).results.filter((r) => (r.width ?? 0) >= 800 && (r.height ?? 0) >= 600);
    await sleep(5000 * attempt);
  }
  console.warn(`search failed for ${query}`);
  return [];
}

async function download(url) {
  const res = await fetch(url, { headers: { 'User-Agent': 'unm-marketplace-seed/1.0' }, redirect: 'follow' });
  if (!res.ok) throw new Error(`download ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
}

if (args.includes('--sheet')) {
  const tiles = [];
  for (const l of listings) {
    const file = path.join(imagesDir, `${l.slug}.webp`);
    const buf = await fs.readFile(file).catch(() => null);
    if (!buf) continue;
    const label = Buffer.from(`<svg width="300" height="40"><rect width="300" height="40" fill="#000a"/><text x="8" y="26" font-size="18" fill="#fff" font-family="sans-serif">${l.slug}</text></svg>`);
    tiles.push(await sharp(buf).resize(300, 225, { fit: 'cover' }).composite([{ input: label, top: 185, left: 0 }]).png().toBuffer());
  }
  const cols = 6;
  const rows = Math.ceil(tiles.length / cols);
  const sheet = sharp({ create: { width: cols * 300, height: rows * 225, channels: 3, background: '#111' } })
    .composite(tiles.map((t, i) => ({ input: t, left: (i % cols) * 300, top: Math.floor(i / cols) * 225 })));
  const out = process.env.SHEET_OUT ?? '/tmp/seed-sheet.png';
  await sheet.png().toFile(out);
  console.log(out);
  process.exit(0);
}

await fs.mkdir(imagesDir, { recursive: true });
for (const l of listings) {
  const file = path.join(imagesDir, `${l.slug}.webp`);
  const forced = picks[l.slug];
  if (forced === undefined && credits[l.slug] && (await fs.stat(file).catch(() => null))) continue;
  const results = await search(l.query);
  let ok = false;
  for (let i = forced ?? 0; i < results.length && !ok; i++) {
    const r = results[i];
    try {
      const raw = await download(r.url);
      const webp = await sharp(raw).rotate().resize(1600, 1600, { fit: 'inside', withoutEnlargement: true }).webp({ quality: 80 }).toBuffer();
      await fs.writeFile(file, webp);
      credits[l.slug] = {
        title: r.title, creator: r.creator, creatorUrl: r.creator_url, license: r.license,
        licenseVersion: r.license_version, licenseUrl: r.license_url, source: r.foreign_landing_url, result: i,
      };
      console.log(`${l.slug}: #${i} ${r.title} by ${r.creator} (${r.license})`);
      ok = true;
    } catch (err) {
      console.warn(`${l.slug}: #${i} failed (${err.message})`);
    }
  }
  if (!ok) console.warn(`${l.slug}: NO PHOTO`);
  await fs.writeFile(creditsFile, JSON.stringify(credits, null, 2) + '\n');
  await sleep(3500);
}

// CREDITS.md for humans.
const lines = ['# Demo photo credits', '', 'Demo listing photos come from [Openverse](https://openverse.org) under the licences below. They were resized and converted to WebP.', ''];
for (const l of listings) {
  const c = credits[l.slug];
  if (!c) continue;
  const lic = c.license === 'cc0' ? 'CC0' : c.license === 'pdm' ? 'Public Domain Mark' : `CC ${c.license.toUpperCase()} ${c.licenseVersion ?? ''}`.trim();
  lines.push(`- **${l.title}**: "${c.title}" by ${c.creator ?? 'unknown'} ([source](${c.source})), ${c.licenseUrl ? `[${lic}](${c.licenseUrl})` : lic}`);
}
await fs.writeFile(path.join(seedDir, 'CREDITS.md'), lines.join('\n') + '\n');
