#!/usr/bin/env node
// Dev-only: render the demo sellers' initials avatars (needs system fonts, so it runs
// on a dev machine, not in the font-less api image). Output is committed.
//   node scripts/make-avatars.mjs
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const seed = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../src/seed');
const users = JSON.parse(await fs.readFile(path.join(seed, 'data/users.json'), 'utf8'));
const out = path.join(seed, 'images/avatars');
await fs.mkdir(out, { recursive: true });
for (const u of users) {
  const [from, to] = u.colors;
  const initials = `${u.firstName[0]}${u.lastName[0]}`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs>
    <rect width="256" height="256" fill="url(#g)"/>
    <text x="128" y="160" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="100" font-weight="700" fill="#fff">${initials}</text>
  </svg>`;
  await sharp(Buffer.from(svg)).webp({ quality: 88 }).toFile(path.join(out, `${u.username}.webp`));
  console.log(u.username, initials);
}
