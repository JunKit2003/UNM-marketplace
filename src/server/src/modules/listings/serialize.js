import { imageUrl } from '../../images/process.js';
import { serializePublicUser } from '../users/serialize.js';

const iso = (d) => (d instanceof Date ? d.toISOString() : d);

export function serializeImage(img) {
  return { id: img.id, url: imageUrl(img.path), position: img.position };
}

/** Row from listingsRepo (listing joined with category + seller + saved flag) → API Listing. */
export function serializeListing(row, images, viewerId) {
  const imgs = images.map(serializeImage);
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    price: Number(row.price),
    condition: row.condition,
    status: row.status,
    category: { id: row.category_id, slug: row.category_slug, name: row.category_name },
    images: imgs,
    coverUrl: imgs[0]?.url ?? null,
    seller: serializePublicUser({
      id: row.seller_id,
      username: row.seller_username,
      first_name: row.seller_first_name,
      last_name: row.seller_last_name,
      avatar_path: row.seller_avatar_path,
    }),
    isSaved: Boolean(row.is_saved),
    isOwner: viewerId != null && row.seller_id === viewerId,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}
