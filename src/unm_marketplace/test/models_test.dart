import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/models.dart';

import 'samples.dart';

void main() {
  test('Listing.fromJson reads the contract shape', () {
    final l = Listing.fromJson(listingJson(price: 12.5, isSaved: true));
    expect(l.id, 1);
    expect(l.price, 12.5);
    expect(l.category.slug, 'home-garden');
    expect(l.images, hasLength(2));
    expect(l.coverUrl, '/images/seed/listings/desk-lamp.webp');
    expect(l.seller.displayName, 'Priya Nair');
    expect(l.isSaved, isTrue);
    expect(l.isSold, isFalse);
    expect(l.createdAt, DateTime.utc(2026, 11, 20, 8));
    expect(l.copyWith(isSaved: false).isSaved, isFalse);
  });

  test('PageResult.fromJson maps items', () {
    final p = PageResult.fromJson({
      'items': [listingJson()],
      'page': 1,
      'pageSize': 24,
      'total': 1,
      'hasMore': false,
    }, Listing.fromJson);
    expect(p.items.single.title, 'LED desk lamp');
    expect(p.hasMore, isFalse);
  });

  test('User, Conversation and Message parse', () {
    final u = User.fromJson(userJson(isGuest: true));
    expect(u.isGuest, isTrue);
    expect(u.email, isNull);
    final c = Conversation.fromJson(conversationJson());
    expect(c.unreadCount, 1);
    expect(c.lastMessage!.body, 'Still available?');
    final m = Message.fromJson(messageJson(readAt: '2026-11-20T09:00:00.000Z'));
    expect(m.isRead, isTrue);
  });
}
