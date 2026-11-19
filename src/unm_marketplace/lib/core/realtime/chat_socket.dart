import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/models.dart';
import '../config.dart';

class IncomingMessage {
  const IncomingMessage(this.conversationId, this.message);
  final int conversationId;
  final Message message;
}

class TypingEvent {
  const TypingEvent(this.conversationId, this.userId);
  final int conversationId;
  final int userId;
}

class ReadEvent {
  const ReadEvent(this.conversationId, this.userId);
  final int conversationId;
  final int userId;
}

/// Live chat over Socket.IO. The browser sends the session cookie with the handshake.
class ChatSocket {
  io.Socket? _socket;
  final _messages = StreamController<IncomingMessage>.broadcast();
  final _typing = StreamController<TypingEvent>.broadcast();
  final _reads = StreamController<ReadEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  Stream<IncomingMessage> get messages => _messages.stream;
  Stream<TypingEvent> get typing => _typing.stream;
  Stream<ReadEvent> get reads => _reads.stream;
  Stream<bool> get connectionChanges => _connected.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;
    final s = io.io(
      apiBase(),
      io.OptionBuilder().setPath('/socket.io').setTransports(['websocket']).enableReconnection().disableAutoConnect().build(),
    );
    s.onConnect((_) => _connected.add(true));
    s.onDisconnect((_) => _connected.add(false));
    s.on('message:new', (data) {
      final m = data as Map;
      _messages.add(IncomingMessage(m['conversationId'] as int, Message.fromJson(Map<String, dynamic>.from(m['message'] as Map))));
    });
    s.on('typing', (data) {
      final m = data as Map;
      _typing.add(TypingEvent(m['conversationId'] as int, m['userId'] as int));
    });
    s.on('conversation:read', (data) {
      final m = data as Map;
      _reads.add(ReadEvent(m['conversationId'] as int, m['userId'] as int));
    });
    s.connect();
    _socket = s;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  /// Send over the socket; falls back to the caller's REST path when not connected.
  Future<Message?> send(int conversationId, String body) async {
    final s = _socket;
    if (s == null || !s.connected) return null;
    final ack = await s.emitWithAckAsync('message:send', {'conversationId': conversationId, 'body': body})
        .timeout(const Duration(seconds: 8), onTimeout: () => null);
    if (ack is Map && ack['ok'] == true) return Message.fromJson(Map<String, dynamic>.from(ack['message'] as Map));
    return null;
  }

  void sendTyping(int conversationId) => _socket?.emit('typing', {'conversationId': conversationId});

  void markRead(int conversationId) => _socket?.emit('conversation:read', {'conversationId': conversationId});
}
