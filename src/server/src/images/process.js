import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import multer from 'multer';
import sharp from 'sharp';
import { badRequest } from '../http/errors.js';

export const PHOTO_ERROR = 'Photos must be JPEG, PNG or WebP, up to 5 MB.';
export const MAX_PHOTO_BYTES = 5 * 1024 * 1024;
export const MAX_PHOTOS = 6;
const ALLOWED = new Set(['jpeg', 'png', 'webp']);

/** Multer instance that keeps files in memory (each ≤ 5 MB, at most 6). */
export const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_PHOTO_BYTES, files: MAX_PHOTOS, fields: 20 },
});

/**
 * Check the bytes really are a JPEG/PNG/WebP (whatever the filename says), then
 * re-encode to WebP no larger than maxSize px on the long edge. Strips metadata.
 */
export async function processImage(buffer, { maxSize = 1600 } = {}) {
  let meta;
  try {
    meta = await sharp(buffer).metadata();
  } catch {
    throw badRequest(PHOTO_ERROR);
  }
  if (!ALLOWED.has(meta.format) || buffer.length > MAX_PHOTO_BYTES) throw badRequest(PHOTO_ERROR);
  try {
    return await sharp(buffer)
      .rotate()
      .resize({ width: maxSize, height: maxSize, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 82 })
      .toBuffer();
  } catch {
    throw badRequest(PHOTO_ERROR);
  }
}

/** Write a processed image under uploadDir/subdir with a random name. Returns the relative path. */
export async function saveUpload(uploadDir, buffer, subdir) {
  const rel = path.posix.join(subdir, `${crypto.randomUUID()}.webp`);
  const abs = path.join(uploadDir, rel);
  await fs.mkdir(path.dirname(abs), { recursive: true });
  await fs.writeFile(abs, buffer);
  return rel;
}

/** Remove an uploaded file; missing files are ignored. Refuses paths outside uploadDir. */
export async function deleteUpload(uploadDir, rel) {
  if (!rel) return;
  const root = path.resolve(uploadDir);
  const abs = path.resolve(root, rel);
  if (!abs.startsWith(root + path.sep)) return;
  await fs.rm(abs, { force: true });
}

export const imageUrl = (rel) => (rel ? `/images/${rel}` : null);
