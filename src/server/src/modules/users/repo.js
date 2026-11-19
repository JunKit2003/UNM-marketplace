import crypto from 'node:crypto';

export async function findUserById(pool, id) {
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [id]);
  return rows[0] ?? null;
}

export async function findUserByEmail(pool, email) {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0] ?? null;
}

export async function insertUser(pool, u) {
  const [res] = await pool.query(
    `INSERT INTO users (username, email, first_name, last_name, phone, password_hash, avatar_path, is_seed, is_guest)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [u.username, u.email ?? null, u.firstName, u.lastName ?? '', u.phone ?? '', u.passwordHash ?? null,
      u.avatarPath ?? null, Boolean(u.isSeed), Boolean(u.isGuest)],
  );
  return findUserById(pool, res.insertId);
}

/** Create a guest buyer with a random username; retries on the (unlikely) collision. */
export async function createGuest(pool) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const username = `guest-${crypto.randomBytes(6).toString('hex').slice(0, 8)}`;
    const number = String(crypto.randomInt(1000, 10000));
    try {
      return await insertUser(pool, { username, firstName: 'Guest', lastName: number, isGuest: true });
    } catch (err) {
      if (err.code !== 'ER_DUP_ENTRY') throw err;
    }
  }
  throw new Error('could not allocate a guest username');
}

export async function updateUser(pool, id, fields) {
  const map = { firstName: 'first_name', lastName: 'last_name', phone: 'phone', avatarPath: 'avatar_path', passwordHash: 'password_hash' };
  const sets = [];
  const vals = [];
  for (const [k, col] of Object.entries(map)) {
    if (fields[k] !== undefined) {
      sets.push(`${col} = ?`);
      vals.push(fields[k]);
    }
  }
  if (sets.length) await pool.query(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`, [...vals, id]);
  return findUserById(pool, id);
}
