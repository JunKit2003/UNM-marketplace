#!/usr/bin/env node
// Dev-only: draw the gradient "N" app icons for the Flutter web build.
//   node scripts/make-icons.mjs ../unm_marketplace/web
import sharp from 'sharp';

const out = process.argv[2] ?? '../unm_marketplace/web';
const svg = (size, pad, rounded) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7C5CFF"/><stop offset="1" stop-color="#22D3EE"/></linearGradient></defs>
  <rect width="${size}" height="${size}" rx="${rounded ? size * 0.28 : 0}" fill="url(#g)"/>
  <text x="50%" y="${size * (0.5 + 0.18 * (1 - pad))}" text-anchor="middle" font-family="DejaVu Sans, sans-serif"
        font-weight="700" font-size="${size * 0.52 * (1 - pad)}" fill="#fff">N</text>
</svg>`);

for (const [name, size, pad, rounded] of [
  ['favicon.png', 64, 0, true],
  ['icons/Icon-192.png', 192, 0, true],
  ['icons/Icon-512.png', 512, 0, true],
  ['icons/Icon-maskable-192.png', 192, 0.25, false],
  ['icons/Icon-maskable-512.png', 512, 0.25, false],
]) {
  await sharp(svg(size, pad, rounded)).png().toFile(`${out}/${name}`);
}
console.log('icons written to', out);
