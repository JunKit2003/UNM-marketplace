const CONVERSATION_SELECT = `
  SELECT c.id, c.listing_id, c.buyer_id, c.seller_id, c.updated_at,
         l.title AS listing_title, l.price AS listing_price, l.status AS listing_status,
         (SELECT path FROM listing_images i WHERE i.listing_id = l.id ORDER BY position, id LIMIT 1) AS cover_path,
         o.id AS other_id, o.username AS other_username, o.first_name AS other_first_name,
         o.last_name AS other_last_name, o.avatar_path AS other_avatar_path,
         m.id AS last_id, m.body AS last_body, m.sender_id AS last_sender_id, m.created_at AS last_created_at,
         (SELECT COUNT(*) FROM messages u
            WHERE u.conversation_id = c.id AND u.sender_id <> ? AND u.read_at IS NULL) AS unread_count
  FROM conversations c
  JOIN listings l ON l.id = c.listing_id
  JOIN users o ON o.id = IF(c.buyer_id = ?, c.seller_id, c.buyer_id)
  LEFT JOIN messages m ON m.id = (SELECT MAX(id) FROM messages x WHERE x.conversation_id = c.id)`;

export async function findConversationRow(pool, id) {
  const [rows] = await pool.query('SELECT * FROM conversations WHERE id = ?', [id]);
  return rows[0] ?? null;
}

export async function findConversationByListingBuyer(pool, listingId, buyerId) {
  const [rows] = await pool.query('SELECT * FROM conversations WHERE listing_id = ? AND buyer_id = ?', [listingId, buyerId]);
  return rows[0] ?? null;
}

/** Insert, or return the existing row if another request created it first. */
export async function insertConversation(pool, listingId, buyerId, sellerId) {
  const [res] = await pool.query(
    'INSERT IGNORE INTO conversations (listing_id, buyer_id, seller_id) VALUES (?, ?, ?)',
    [listingId, buyerId, sellerId],
  );
  return { row: await findConversationByListingBuyer(pool, listingId, buyerId), created: res.affectedRows === 1 };
}

export async function conversationsFor(pool, userId, conversationId = null) {
  const params = [userId, userId, userId, userId];
  let filter = 'WHERE (c.buyer_id = ? OR c.seller_id = ?)';
  if (conversationId) {
    filter += ' AND c.id = ?';
    params.push(conversationId);
  }
  const [rows] = await pool.query(`${CONVERSATION_SELECT} ${filter} ORDER BY c.updated_at DESC, c.id DESC`, params);
  return rows;
}

export async function insertMessage(pool, conversationId, senderId, body) {
  const [res] = await pool.query('INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)', [conversationId, senderId, body]);
  await pool.query('UPDATE conversations SET updated_at = CURRENT_TIMESTAMP(3) WHERE id = ?', [conversationId]);
  const [rows] = await pool.query('SELECT * FROM messages WHERE id = ?', [res.insertId]);
  return rows[0];
}

export async function messagesFor(pool, conversationId, { before, limit }) {
  const params = [conversationId];
  let extra = '';
  if (before) {
    extra = ' AND id < ?';
    params.push(before);
  }
  params.push(limit);
  const [rows] = await pool.query(`SELECT * FROM messages WHERE conversation_id = ?${extra} ORDER BY id DESC LIMIT ?`, params);
  return rows.reverse();
}

export async function markRead(pool, conversationId, userId) {
  const [res] = await pool.query(
    'UPDATE messages SET read_at = CURRENT_TIMESTAMP(3) WHERE conversation_id = ? AND sender_id <> ? AND read_at IS NULL',
    [conversationId, userId],
  );
  return res.affectedRows;
}

export async function unreadTotal(pool, userId) {
  const [[{ n }]] = await pool.query(
    `SELECT COUNT(*) AS n FROM messages m JOIN conversations c ON c.id = m.conversation_id
     WHERE (c.buyer_id = ? OR c.seller_id = ?) AND m.sender_id <> ? AND m.read_at IS NULL`,
    [userId, userId, userId],
  );
  return Number(n);
}
