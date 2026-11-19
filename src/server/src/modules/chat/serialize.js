import { imageUrl } from '../../images/process.js';
import { serializePublicUser } from '../users/serialize.js';

const iso = (d) => (d instanceof Date ? d.toISOString() : d);

export function serializeMessage(m) {
  return {
    id: m.id,
    conversationId: m.conversation_id,
    senderId: m.sender_id,
    body: m.body,
    createdAt: iso(m.created_at),
    readAt: m.read_at ? iso(m.read_at) : null,
  };
}

/** Row from chatRepo.conversationsFor (already joined from the viewer's side). */
export function serializeConversation(r) {
  return {
    id: r.id,
    listing: {
      id: r.listing_id,
      title: r.listing_title,
      price: Number(r.listing_price),
      status: r.listing_status,
      coverUrl: imageUrl(r.cover_path),
    },
    otherUser: serializePublicUser({
      id: r.other_id,
      username: r.other_username,
      first_name: r.other_first_name,
      last_name: r.other_last_name,
      avatar_path: r.other_avatar_path,
    }),
    lastMessage: r.last_id
      ? { body: r.last_body, senderId: r.last_sender_id, createdAt: iso(r.last_created_at) }
      : null,
    unreadCount: Number(r.unread_count),
    updatedAt: iso(r.updated_at),
  };
}
