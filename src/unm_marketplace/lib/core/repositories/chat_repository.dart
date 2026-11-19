import 'package:dio/dio.dart';

import '../api/api_error.dart';
import '../api/models.dart';

class ChatRepository {
  ChatRepository(this._dio);
  final Dio _dio;

  Conversation _conv(Response r) => Conversation.fromJson(r.data as Map<String, dynamic>);

  Future<List<Conversation>> list() => guard(() async {
        final r = await _dio.get('/conversations');
        return [for (final j in r.data as List) Conversation.fromJson(j as Map<String, dynamic>)];
      });

  Future<Conversation> get(int id) => guard(() async => _conv(await _dio.get('/conversations/$id')));

  Future<Conversation> start(int listingId) =>
      guard(() async => _conv(await _dio.post('/listings/$listingId/conversations')));

  Future<List<Message>> messages(int id, {int? before, int limit = 50}) => guard(() async {
        final r = await _dio.get('/conversations/$id/messages', queryParameters: {'before': ?before, 'limit': limit});
        return [for (final j in r.data as List) Message.fromJson(j as Map<String, dynamic>)];
      });

  Future<Message> send(int id, String body) => guard(() async {
        final r = await _dio.post('/conversations/$id/messages', data: {'body': body});
        return Message.fromJson(r.data as Map<String, dynamic>);
      });

  Future<void> read(int id) => guard(() => _dio.post('/conversations/$id/read'));

  Future<int> unread() => guard(() async => ((await _dio.get('/me/unread')).data as Map)['count'] as int);
}
