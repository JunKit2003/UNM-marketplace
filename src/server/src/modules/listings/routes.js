import { badRequest, forbidden, notFound } from '../../http/errors.js';
import { requireUser } from '../../http/auth.js';
import { validate } from '../../http/validate.js';
import { deleteUpload, imageUpload, MAX_PHOTOS, processImage, saveUpload } from '../../images/process.js';
import {
  categoryIdBySlug, findListing, findListingRow, imagesFor, listingsBySeller, searchListings,
} from './repo.js';
import {
  browseQuerySchema, createListingSchema, myListingsQuerySchema, reorderSchema, updateListingSchema,
} from './schemas.js';

export const LISTING_GONE = "This listing doesn't exist or was removed.";
const TOO_MANY = 'A listing can have up to 6 photos.';

export function parseId(raw) {
  const id = Number(raw);
  return Number.isInteger(id) && id > 0 && id < 2 ** 32 ? id : null;
}

/** Load a listing the current user owns, or throw 404 / 403. */
export async function ownedListing(pool, rawId, userId) {
  const id = parseId(rawId);
  const row = id && (await findListingRow(pool, id));
  if (!row) throw notFound(LISTING_GONE);
  if (row.seller_id !== userId) throw forbidden('Only the seller can change this listing.');
  return row;
}

async function processAll(files) {
  const out = [];
  for (const f of files) out.push(await processImage(f.buffer, { maxSize: 1600 }));
  return out;
}

async function storeImages(pool, uploadDir, listingId, buffers, startPosition) {
  const paths = [];
  try {
    for (const b of buffers) paths.push(await saveUpload(uploadDir, b, 'listings'));
    await pool.query(
      'INSERT INTO listing_images (listing_id, path, position) VALUES ?',
      [paths.map((p, i) => [listingId, p, startPosition + i])],
    );
  } catch (err) {
    await Promise.all(paths.map((p) => deleteUpload(uploadDir, p)));
    throw err;
  }
}

async function renumber(pool, listingId, orderedIds) {
  for (const [i, imageId] of orderedIds.entries()) {
    await pool.query('UPDATE listing_images SET position = ? WHERE id = ? AND listing_id = ?', [i, imageId, listingId]);
  }
}

export function registerListings(api, { pool, config, limits }) {
  const viewer = (req) => req.session?.userId ?? null;

  api.get('/categories', async (req, res) => {
    const [rows] = await pool.query(
      `SELECT c.id, c.slug, c.name, c.icon,
              (SELECT COUNT(*) FROM listings l WHERE l.category_id = c.id AND l.status = 'active') AS count
       FROM categories c ORDER BY c.position`,
    );
    res.json(rows.map((r) => ({ ...r, count: Number(r.count) })));
  });

  api.get('/listings', validate(browseQuerySchema, 'query'), async (req, res) => {
    res.json(await searchListings(pool, req.valid.query, viewer(req)));
  });

  api.get('/listings/:id', async (req, res) => {
    const id = parseId(req.params.id);
    const listing = id && (await findListing(pool, id, viewer(req)));
    if (!listing) throw notFound(LISTING_GONE);
    res.json(listing);
  });

  api.post(
    '/listings',
    requireUser,
    limits.createListing,
    imageUpload.array('photos', MAX_PHOTOS),
    validate(createListingSchema),
    async (req, res) => {
      const b = req.valid.body;
      const files = req.files ?? [];
      if (!files.length) throw badRequest('Add at least one photo.', { photos: 'Add at least one photo.' });
      const categoryId = await categoryIdBySlug(pool, b.categorySlug);
      if (!categoryId) throw badRequest('Pick a category.', { categorySlug: 'Pick a category.' });
      const buffers = await processAll(files);
      const [ins] = await pool.query(
        'INSERT INTO listings (seller_id, category_id, title, description, price, `condition`) VALUES (?, ?, ?, ?, ?, ?)',
        [req.session.userId, categoryId, b.title, b.description, b.price, b.condition],
      );
      try {
        await storeImages(pool, config.uploadDir, ins.insertId, buffers, 0);
      } catch (err) {
        await pool.query('DELETE FROM listings WHERE id = ?', [ins.insertId]);
        throw err;
      }
      res.status(201).json(await findListing(pool, ins.insertId, req.session.userId));
    },
  );

  api.patch('/listings/:id', requireUser, validate(updateListingSchema), async (req, res) => {
    const row = await ownedListing(pool, req.params.id, req.session.userId);
    const b = req.valid.body;
    const sets = [];
    const vals = [];
    if (b.categorySlug !== undefined) {
      const categoryId = await categoryIdBySlug(pool, b.categorySlug);
      if (!categoryId) throw badRequest('Pick a category.', { categorySlug: 'Pick a category.' });
      sets.push('category_id = ?');
      vals.push(categoryId);
    }
    for (const [k, col] of [['title', 'title'], ['description', 'description'], ['price', 'price'], ['condition', '`condition`'], ['status', 'status']]) {
      if (b[k] !== undefined) {
        sets.push(`${col} = ?`);
        vals.push(b[k]);
      }
    }
    if (sets.length) await pool.query(`UPDATE listings SET ${sets.join(', ')} WHERE id = ?`, [...vals, row.id]);
    res.json(await findListing(pool, row.id, req.session.userId));
  });

  api.delete('/listings/:id', requireUser, async (req, res) => {
    const row = await ownedListing(pool, req.params.id, req.session.userId);
    const images = (await imagesFor(pool, [row.id])).get(row.id);
    await pool.query('DELETE FROM listings WHERE id = ?', [row.id]);
    await Promise.all(images.map((img) => deleteUpload(config.uploadDir, img.path)));
    res.status(204).end();
  });

  api.post('/listings/:id/images', requireUser, limits.uploads, imageUpload.array('photos', MAX_PHOTOS), async (req, res) => {
    const row = await ownedListing(pool, req.params.id, req.session.userId);
    const files = req.files ?? [];
    if (!files.length) throw badRequest('Add at least one photo.', { photos: 'Add at least one photo.' });
    const existing = (await imagesFor(pool, [row.id])).get(row.id);
    if (existing.length + files.length > MAX_PHOTOS) throw badRequest(TOO_MANY, { photos: TOO_MANY });
    const buffers = await processAll(files);
    const nextPos = existing.length ? Math.max(...existing.map((i) => i.position)) + 1 : 0;
    await storeImages(pool, config.uploadDir, row.id, buffers, nextPos);
    res.json(await findListing(pool, row.id, req.session.userId));
  });

  api.delete('/listings/:id/images/:imageId', requireUser, async (req, res) => {
    const row = await ownedListing(pool, req.params.id, req.session.userId);
    const images = (await imagesFor(pool, [row.id])).get(row.id);
    const target = images.find((i) => i.id === parseId(req.params.imageId));
    if (!target) throw notFound('That photo is not on this listing.');
    if (images.length === 1) throw badRequest('A listing needs at least one photo.');
    await pool.query('DELETE FROM listing_images WHERE id = ?', [target.id]);
    await deleteUpload(config.uploadDir, target.path);
    await renumber(pool, row.id, images.filter((i) => i.id !== target.id).map((i) => i.id));
    res.json(await findListing(pool, row.id, req.session.userId));
  });

  api.put('/listings/:id/images/order', requireUser, validate(reorderSchema), async (req, res) => {
    const row = await ownedListing(pool, req.params.id, req.session.userId);
    const images = (await imagesFor(pool, [row.id])).get(row.id);
    const want = req.valid.body.imageIds;
    const have = new Set(images.map((i) => i.id));
    if (want.length !== have.size || new Set(want).size !== want.length || !want.every((id) => have.has(id))) {
      throw badRequest("The new order must list each of this listing's photos once.");
    }
    await renumber(pool, row.id, want);
    res.json(await findListing(pool, row.id, req.session.userId));
  });

  api.get('/me/listings', requireUser, validate(myListingsQuerySchema, 'query'), async (req, res) => {
    res.json(await listingsBySeller(pool, req.session.userId, req.valid.query.status));
  });
}
