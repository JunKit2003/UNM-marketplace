import { imageUrl } from '../../images/process.js';

const iso = (d) => (d instanceof Date ? d.toISOString() : d);

export function displayName(row) {
  return `${row.first_name} ${row.last_name ?? ''}`.trim();
}

/** Public view of a user (sellers, chat partners). */
export function serializePublicUser(row) {
  return {
    id: row.id,
    username: row.username,
    displayName: displayName(row),
    avatarUrl: imageUrl(row.avatar_path),
  };
}

/** The logged-in user's own view, including contact details. */
export function serializeUser(row) {
  return {
    ...serializePublicUser(row),
    firstName: row.first_name,
    lastName: row.last_name,
    email: row.email,
    phone: row.phone,
    isGuest: Boolean(row.is_guest),
    createdAt: iso(row.created_at),
  };
}
