import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:unm_marketplace/core/api/api_error.dart';
import 'package:unm_marketplace/core/api/models.dart';
import 'package:unm_marketplace/core/realtime/chat_socket.dart';
import 'package:unm_marketplace/core/repositories/auth_repository.dart';
import 'package:unm_marketplace/core/repositories/chat_repository.dart';
import 'package:unm_marketplace/core/repositories/listings_repository.dart';
import 'package:unm_marketplace/state/providers.dart';

import 'samples.dart';

User fakeUser({bool isGuest = false}) => User.fromJson(userJson(isGuest: isGuest));

class FakeAuthRepository implements AuthRepository {
  User? user;
  ApiError? signupError;
  ApiError? loginError;
  final calls = <String>[];

  @override
  Future<User?> me() async => user;
  @override
  Future<User> login(String email, String password) async {
    calls.add('login');
    if (loginError != null) throw loginError!;
    return user = fakeUser();
  }

  @override
  Future<User> signup(SignupData data) async {
    calls.add('signup');
    if (signupError != null) throw signupError!;
    return user = fakeUser();
  }

  @override
  Future<User> demo() async {
    calls.add('demo');
    return user = fakeUser(isGuest: true);
  }

  @override
  Future<void> logout() async => user = null;
  @override
  Future<User> updateProfile({String? firstName, String? lastName, String? phone}) async => user!;
  @override
  Future<void> changePassword(String current, String next) async => calls.add('password');
  @override
  Future<User> uploadAvatar(PickedPhoto photo) async => user!;
}

class FakeListingsRepository implements ListingsRepository {
  List<Listing> listings = [Listing.fromJson(listingJson())];
  List<Category> cats = const [Category(id: 3, slug: 'home-garden', name: 'Home & Garden', icon: 'chair', count: 1)];
  final searches = <(BrowseFilters, int)>[];
  int pageSize = 24;
  int total = 1;
  ListingDraft? created;
  List<PickedPhoto>? createdPhotos;
  final saves = <int>[];

  @override
  Future<List<Category>> categories() async => cats;
  @override
  Future<PageResult<Listing>> search(BrowseFilters f, {int page = 1}) async {
    searches.add((f, page));
    final start = (page - 1) * pageSize;
    final items = listings.skip(start).take(pageSize).toList();
    return PageResult(items: items, page: page, pageSize: pageSize, total: total, hasMore: start + items.length < total);
  }

  @override
  Future<Listing> get(int id) async => listings.firstWhere(
        (l) => l.id == id,
        orElse: () => throw ApiError(status: 404, code: 'not_found', message: "This listing doesn't exist or was removed."),
      );
  @override
  Future<Listing> create(ListingDraft draft, List<PickedPhoto> photos) async {
    created = draft;
    createdPhotos = photos;
    return listings.first;
  }

  @override
  Future<Listing> update(int id, Map<String, dynamic> fields) async => listings.first;
  @override
  Future<void> delete(int id) async => listings.removeWhere((l) => l.id == id);
  @override
  Future<Listing> addImages(int id, List<PickedPhoto> photos) async => listings.first;
  @override
  Future<Listing> deleteImage(int id, int imageId) async => listings.first;
  @override
  Future<Listing> reorderImages(int id, List<int> imageIds) async => listings.first;
  @override
  Future<List<Listing>> mine({String? status}) async => listings;
  @override
  Future<List<Listing>> saved() async => listings.where((l) => l.isSaved).toList();
  @override
  Future<void> save(int id) async => saves.add(id);
  @override
  Future<void> unsave(int id) async => saves.add(-id);
}

class FakeChatRepository implements ChatRepository {
  List<Conversation> conversations = [Conversation.fromJson(conversationJson())];
  List<Message> history = [Message.fromJson(messageJson())];
  ApiError? getError;
  final sent = <String>[];
  final reads = <int>[];
  bool failSend = false;

  @override
  Future<List<Conversation>> list() async => conversations;
  @override
  Future<Conversation> get(int id) async {
    if (getError != null) throw getError!;
    return conversations.firstWhere((c) => c.id == id);
  }

  @override
  Future<Conversation> start(int listingId) async => conversations.first;
  @override
  Future<List<Message>> messages(int id, {int? before, int limit = 50}) async => before == null ? history : [];
  @override
  Future<Message> send(int id, String body) async {
    if (failSend) throw ApiError(status: 0, code: 'network', message: 'offline');
    sent.add(body);
    return Message.fromJson(messageJson(id: 900 + sent.length, senderId: 42, body: body));
  }

  @override
  Future<void> read(int id) async => reads.add(id);
  @override
  Future<int> unread() async => conversations.fold<int>(0, (a, c) => a + c.unreadCount);
}

class FakeChatSocket implements ChatSocket {
  final messagesCtl = StreamController<IncomingMessage>.broadcast();
  final typingCtl = StreamController<TypingEvent>.broadcast();
  final readsCtl = StreamController<ReadEvent>.broadcast();
  bool connected = false;
  final typed = <int>[];
  final readMarks = <int>[];

  @override
  Stream<IncomingMessage> get messages => messagesCtl.stream;
  @override
  Stream<TypingEvent> get typing => typingCtl.stream;
  @override
  Stream<ReadEvent> get reads => readsCtl.stream;
  @override
  Stream<bool> get connectionChanges => const Stream.empty();
  @override
  bool get isConnected => connected;
  @override
  void connect() => connected = true;
  @override
  void disconnect() => connected = false;
  @override
  Future<Message?> send(int conversationId, String body) async => null;
  @override
  void sendTyping(int conversationId) => typed.add(conversationId);
  @override
  void markRead(int conversationId) => readMarks.add(conversationId);
}

/// Everything the app talks to, faked.
class Fakes {
  final auth = FakeAuthRepository();
  final listings = FakeListingsRepository();
  final chat = FakeChatRepository();
  final socket = FakeChatSocket();

  List<Override> overrides() => [
        dioProvider.overrideWithValue(Dio()),
        authRepositoryProvider.overrideWithValue(auth),
        listingsRepositoryProvider.overrideWithValue(listings),
        chatRepositoryProvider.overrideWithValue(chat),
        chatSocketProvider.overrideWithValue(socket),
      ];
}
