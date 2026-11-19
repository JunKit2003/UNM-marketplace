import 'dart:typed_data';

DateTime _date(Object? v) => DateTime.parse(v as String);
DateTime? _dateOrNull(Object? v) =>
    v == null ? null : DateTime.parse(v as String);
num _num(Object? v) => v is num ? v : num.parse('$v');

class PublicUser {
  const PublicUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  factory PublicUser.fromJson(Map<String, dynamic> j) => PublicUser(
    id: j['id'] as int,
    username: j['username'] as String,
    displayName: j['displayName'] as String,
    avatarUrl: j['avatarUrl'] as String?,
  );

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}

class User extends PublicUser {
  const User({
    required super.id,
    required super.username,
    required super.displayName,
    super.avatarUrl,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    required this.isGuest,
    required this.createdAt,
  });

  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final bool isGuest;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int,
    username: j['username'] as String,
    displayName: j['displayName'] as String,
    avatarUrl: j['avatarUrl'] as String?,
    firstName: j['firstName'] as String,
    lastName: (j['lastName'] as String?) ?? '',
    email: j['email'] as String?,
    phone: (j['phone'] as String?) ?? '',
    isGuest: j['isGuest'] as bool,
    createdAt: _date(j['createdAt']),
  );
}

class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.name,
    this.icon = 'category',
    this.count = 0,
  });
  final int id;
  final String slug;
  final String name;
  final String icon;
  final int count;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as int,
    slug: j['slug'] as String,
    name: j['name'] as String,
    icon: (j['icon'] as String?) ?? 'category',
    count: (j['count'] as int?) ?? 0,
  );
}

class ListingImage {
  const ListingImage({
    required this.id,
    required this.url,
    required this.position,
  });
  final int id;
  final String url;
  final int position;

  factory ListingImage.fromJson(Map<String, dynamic> j) => ListingImage(
    id: j['id'] as int,
    url: j['url'] as String,
    position: j['position'] as int,
  );
}

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.status,
    required this.category,
    required this.images,
    required this.coverUrl,
    required this.seller,
    required this.isSaved,
    required this.isOwner,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final num price;
  final String condition;
  final String status;
  final Category category;
  final List<ListingImage> images;
  final String? coverUrl;
  final PublicUser seller;
  final bool isSaved;
  final bool isOwner;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSold => status == 'sold';

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
    id: j['id'] as int,
    title: j['title'] as String,
    description: j['description'] as String,
    price: _num(j['price']),
    condition: j['condition'] as String,
    status: j['status'] as String,
    category: Category.fromJson(j['category'] as Map<String, dynamic>),
    images: [
      for (final i in j['images'] as List)
        ListingImage.fromJson(i as Map<String, dynamic>),
    ],
    coverUrl: j['coverUrl'] as String?,
    seller: PublicUser.fromJson(j['seller'] as Map<String, dynamic>),
    isSaved: j['isSaved'] as bool,
    isOwner: j['isOwner'] as bool,
    createdAt: _date(j['createdAt']),
    updatedAt: _date(j['updatedAt']),
  );

  Listing copyWith({bool? isSaved, String? status}) => Listing(
    id: id,
    title: title,
    description: description,
    price: price,
    condition: condition,
    status: status ?? this.status,
    category: category,
    images: images,
    coverUrl: coverUrl,
    seller: seller,
    isSaved: isSaved ?? this.isSaved,
    isOwner: isOwner,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory PageResult.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) item,
  ) => PageResult(
    items: [
      for (final i in j['items'] as List) item(i as Map<String, dynamic>),
    ],
    page: j['page'] as int,
    pageSize: j['pageSize'] as int,
    total: j['total'] as int,
    hasMore: j['hasMore'] as bool,
  );
}

class ConversationListing {
  const ConversationListing({
    required this.id,
    required this.title,
    required this.price,
    required this.status,
    this.coverUrl,
  });
  final int id;
  final String title;
  final num price;
  final String status;
  final String? coverUrl;
}

class LastMessage {
  const LastMessage({
    required this.body,
    required this.senderId,
    required this.createdAt,
  });
  final String body;
  final int senderId;
  final DateTime createdAt;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.listing,
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  final int id;
  final ConversationListing listing;
  final PublicUser otherUser;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final l = j['listing'] as Map<String, dynamic>;
    final m = j['lastMessage'] as Map<String, dynamic>?;
    return Conversation(
      id: j['id'] as int,
      listing: ConversationListing(
        id: l['id'] as int,
        title: l['title'] as String,
        price: _num(l['price']),
        status: l['status'] as String,
        coverUrl: l['coverUrl'] as String?,
      ),
      otherUser: PublicUser.fromJson(j['otherUser'] as Map<String, dynamic>),
      lastMessage: m == null
          ? null
          : LastMessage(
              body: m['body'] as String,
              senderId: m['senderId'] as int,
              createdAt: _date(m['createdAt']),
            ),
      unreadCount: j['unreadCount'] as int,
      updatedAt: _date(j['updatedAt']),
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'] as int,
    conversationId: j['conversationId'] as int,
    senderId: j['senderId'] as int,
    body: j['body'] as String,
    createdAt: _date(j['createdAt']),
    readAt: _dateOrNull(j['readAt']),
  );

  Message markRead(DateTime at) => Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    body: body,
    createdAt: createdAt,
    readAt: at,
  );
}

/// A photo chosen in the browser, not yet uploaded.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name, this.mimeType});
  final Uint8List bytes;
  final String name;
  final String? mimeType;
}

const conditions = [
  'Brand new',
  'Like new',
  'Lightly used',
  'Well used',
  'Heavily used',
];
