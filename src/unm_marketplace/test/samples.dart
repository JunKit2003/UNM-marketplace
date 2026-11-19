// JSON samples matching the API contract in docs/plans/2026-11-20-revamp-containers-plan.md.
Map<String, dynamic> sellerJson({int id = 7, String username = 'priya'}) => {
  'id': id,
  'username': username,
  'displayName': 'Priya Nair',
  'avatarUrl': '/images/seed/avatars/priya.webp',
};

Map<String, dynamic> listingJson({
  int id = 1,
  String title = 'LED desk lamp',
  num price = 45,
  String status = 'active',
  bool isOwner = false,
  bool isSaved = false,
  String createdAt = '2026-11-20T08:00:00.000Z',
}) => {
  'id': id,
  'title': title,
  'description': 'Three colour temperatures.',
  'price': price,
  'condition': 'Like new',
  'status': status,
  'category': {'id': 3, 'slug': 'home-garden', 'name': 'Home & Garden'},
  'images': [
    {'id': 11, 'url': '/images/seed/listings/desk-lamp.webp', 'position': 0},
    {'id': 12, 'url': '/images/listings/b.webp', 'position': 1},
  ],
  'coverUrl': '/images/seed/listings/desk-lamp.webp',
  'seller': sellerJson(),
  'isSaved': isSaved,
  'isOwner': isOwner,
  'createdAt': createdAt,
  'updatedAt': createdAt,
};

Map<String, dynamic> userJson({bool isGuest = false}) => {
  'id': 42,
  'username': isGuest ? 'guest-ab12cd34' : 'amy1',
  'displayName': isGuest ? 'Guest 4821' : 'Amy Tester',
  'firstName': isGuest ? 'Guest' : 'Amy',
  'lastName': isGuest ? '4821' : 'Tester',
  'email': isGuest ? null : 'amy1@nottingham.edu.my',
  'phone': '',
  'avatarUrl': null,
  'isGuest': isGuest,
  'createdAt': '2026-11-20T08:00:00.000Z',
};

Map<String, dynamic> conversationJson({
  int id = 5,
  int unread = 1,
  String status = 'active',
}) => {
  'id': id,
  'listing': {
    'id': 1,
    'title': 'LED desk lamp',
    'price': 45,
    'status': status,
    'coverUrl': '/images/x.webp',
  },
  'otherUser': sellerJson(),
  'lastMessage': {
    'body': 'Still available?',
    'senderId': 7,
    'createdAt': '2026-11-20T08:00:00.000Z',
  },
  'unreadCount': unread,
  'updatedAt': '2026-11-20T08:00:00.000Z',
};

Map<String, dynamic> messageJson({
  int id = 100,
  int senderId = 7,
  String body = 'Hi!',
  String? readAt,
}) => {
  'id': id,
  'conversationId': 5,
  'senderId': senderId,
  'body': body,
  'createdAt': '2026-11-20T08:00:00.000Z',
  'readAt': readAt,
};
