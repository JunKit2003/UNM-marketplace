import { PAGE_SIZE } from './schemas.js';
import { serializeListing } from './serialize.js';

const SELECT = `
  SELECT l.*, c.slug AS category_slug, c.name AS category_name,
         u.username AS seller_username, u.first_name AS seller_first_name,
         u.last_name AS seller_last_name, u.avatar_path AS seller_avatar_path,
         (s.user_id IS NOT NULL) AS is_saved
  FROM listings l
  JOIN categories c ON c.id = l.category_id
  JOIN users u ON u.id = l.seller_id
  LEFT JOIN saved_listings s ON s.listing_id = l.id AND s.user_id = ?`;

const ORDER = {
  newest: 'l.created_at DESC, l.id DESC',
  price_asc: 'l.price ASC, l.created_at DESC, l.id DESC',
  price_desc: 'l.price DESC, l.created_at DESC, l.id DESC',
};

export async function imagesFor(pool, listingIds) {
  const byListing = new Map(listingIds.map((id) => [id, []]));
  if (!listingIds.length) return byListing;
  const [rows] = await pool.query(
    'SELECT * FROM listing_images WHERE listing_id IN (?) ORDER BY position, id',
    [listingIds],
  );
  for (const r of rows) byListing.get(r.listing_id)?.push(r);
  return byListing;
}

async function hydrate(pool, rows, viewerId) {
  const images = await imagesFor(pool, rows.map((r) => r.id));
  return rows.map((r) => serializeListing(r, images.get(r.id) ?? [], viewerId));
}

export async function findListingRow(pool, id) {
  const [rows] = await pool.query('SELECT * FROM listings WHERE id = ?', [id]);
  return rows[0] ?? null;
}

export async function findListing(pool, id, viewerId) {
  const [rows] = await pool.query(`${SELECT} WHERE l.id = ?`, [viewerId ?? 0, id]);
  if (!rows.length) return null;
  return (await hydrate(pool, rows, viewerId))[0];
}

/** Turn free text into a safe InnoDB boolean-mode query: every word required, prefix match. */
function booleanQuery(q) {
  const words = q.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((w) => w.length >= 3);
  return words.map((w) => `+${w}*`).join(' ');
}

export async function searchListings(pool, f, viewerId) {
  const where = [];
  const params = [];
  if (f.status !== 'all') {
    where.push('l.status = ?');
    params.push(f.status);
  }
  if (f.q) {
    const bq = booleanQuery(f.q);
    if (bq) {
      where.push('MATCH(l.title, l.description) AGAINST (? IN BOOLEAN MODE)');
      params.push(bq);
    } else {
      where.push('(l.title LIKE ? OR l.description LIKE ?)');
      const like = `%${f.q.replace(/[\\%_]/g, (m) => `\\${m}`)}%`;
      params.push(like, like);
    }
  }
  if (f.category) {
    where.push('c.slug = ?');
    params.push(f.category);
  }
  if (f.condition) {
    where.push('l.`condition` = ?');
    params.push(f.condition);
  }
  if (f.min != null) {
    where.push('l.price >= ?');
    params.push(f.min);
  }
  if (f.max != null) {
    where.push('l.price <= ?');
    params.push(f.max);
  }
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [[{ total }]] = await pool.query(
    `SELECT COUNT(*) AS total FROM listings l JOIN categories c ON c.id = l.category_id ${whereSql}`,
    params,
  );
  const offset = (f.page - 1) * PAGE_SIZE;
  const [rows] = await pool.query(
    `${SELECT} ${whereSql} ORDER BY ${ORDER[f.sort]} LIMIT ? OFFSET ?`,
    [viewerId ?? 0, ...params, PAGE_SIZE, offset],
  );
  return {
    items: await hydrate(pool, rows, viewerId),
    page: f.page,
    pageSize: PAGE_SIZE,
    total: Number(total),
    hasMore: offset + rows.length < Number(total),
  };
}

export async function listingsBySeller(pool, sellerId, status) {
  const params = [sellerId, sellerId];
  let extra = '';
  if (status) {
    extra = ' AND l.status = ?';
    params.push(status);
  }
  const [rows] = await pool.query(`${SELECT} WHERE l.seller_id = ?${extra} ORDER BY l.created_at DESC, l.id DESC`, params);
  return hydrate(pool, rows, sellerId);
}

export async function savedListings(pool, userId) {
  const [rows] = await pool.query(`${SELECT} WHERE s.user_id IS NOT NULL ORDER BY s.created_at DESC, l.id DESC`, [userId]);
  return hydrate(pool, rows, userId);
}

export async function categoryIdBySlug(pool, slug) {
  const [rows] = await pool.query('SELECT id FROM categories WHERE slug = ?', [slug]);
  return rows[0]?.id ?? null;
}
