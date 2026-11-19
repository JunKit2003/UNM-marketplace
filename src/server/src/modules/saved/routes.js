import { notFound } from '../../http/errors.js';
import { requireUser } from '../../http/auth.js';
import { findListingRow, savedListings } from '../listings/repo.js';
import { LISTING_GONE, parseId } from '../listings/routes.js';

export function registerSaved(api, { pool }) {
  api.get('/me/saved', requireUser, async (req, res) => {
    res.json(await savedListings(pool, req.session.userId));
  });

  api.put('/listings/:id/save', requireUser, async (req, res) => {
    const id = parseId(req.params.id);
    if (!id || !(await findListingRow(pool, id))) throw notFound(LISTING_GONE);
    await pool.query('INSERT IGNORE INTO saved_listings (user_id, listing_id) VALUES (?, ?)', [req.session.userId, id]);
    res.status(204).end();
  });

  api.delete('/listings/:id/save', requireUser, async (req, res) => {
    const id = parseId(req.params.id);
    if (id) await pool.query('DELETE FROM saved_listings WHERE user_id = ? AND listing_id = ?', [req.session.userId, id]);
    res.status(204).end();
  });
}
