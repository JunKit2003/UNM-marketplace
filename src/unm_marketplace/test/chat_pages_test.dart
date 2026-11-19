import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/api_error.dart';
import 'package:unm_marketplace/core/api/models.dart';
import 'package:unm_marketplace/core/realtime/chat_socket.dart';

import 'fakes.dart';
import 'harness.dart';
import 'samples.dart';

Fakes signedIn() => Fakes()..auth.user = fakeUser();

void main() {
  testWidgets('inbox lists conversations with an unread badge', (tester) async {
    final fakes = signedIn()..chat.conversations = [Conversation.fromJson(conversationJson(unread: 3))];
    await pumpApp(tester, fakes, '/messages', size: const Size(390, 844));
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Still available?'), findsOneWidget);
    expect(find.byKey(const Key('unread-5')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('unread-5')), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('empty inbox copy', (tester) async {
    final fakes = signedIn()..chat.conversations = [];
    await pumpApp(tester, fakes, '/messages');
    expect(find.text('No chats yet. Find something you like and message the seller.'), findsOneWidget);
  });

  testWidgets('thread shows history and marks it read on open', (tester) async {
    final fakes = signedIn();
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    expect(find.text('Hi!'), findsOneWidget);
    expect(find.text('LED desk lamp'), findsWidgets);
    expect(fakes.chat.reads, contains(5));
  });

  testWidgets('incoming live message appears and is marked read', (tester) async {
    final fakes = signedIn();
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    fakes.socket.readMarks.clear();
    fakes.socket.messagesCtl.add(IncomingMessage(5, Message.fromJson(messageJson(id: 101, body: 'Yes, still here!'))));
    await settle(tester);
    expect(find.text('Yes, still here!'), findsOneWidget);
    expect(fakes.socket.readMarks, [5]);
  });

  testWidgets('typing dots appear and fade after 3 seconds', (tester) async {
    final fakes = signedIn();
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    fakes.socket.typingCtl.add(const TypingEvent(5, 7));
    await settle(tester, frames: 4);
    expect(find.byKey(const Key('typing-dots')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, frames: 10);
    expect(find.byKey(const Key('typing-dots')), findsNothing);
  });

  testWidgets('sending shows the message straight away and confirms it', (tester) async {
    final fakes = signedIn();
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    await tester.enterText(find.byKey(const Key('composer')), 'Can we meet at the library?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(find.text('Can we meet at the library?'), findsOneWidget);
    await settle(tester);
    expect(fakes.chat.sent, ['Can we meet at the library?']);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('a failed send can be retried', (tester) async {
    final fakes = signedIn()..chat.failSend = true;
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    await tester.enterText(find.byKey(const Key('composer')), 'hello?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await settle(tester);
    expect(find.text('Not sent. Tap to retry.'), findsOneWidget);
    fakes.chat.failSend = false;
    await tester.tap(find.text('Not sent. Tap to retry.'));
    await settle(tester);
    expect(fakes.chat.sent, ['hello?']);
    expect(find.text('Not sent. Tap to retry.'), findsNothing);
  });

  testWidgets('a thread whose listing was removed disables the composer', (tester) async {
    final fakes = signedIn()
      ..chat.getError = ApiError(status: 404, code: 'not_found', message: 'This listing was removed.');
    await pumpApp(tester, fakes, '/messages/5', size: const Size(390, 844));
    expect(find.text('This listing was removed.'), findsOneWidget);
    final field = tester.widget<TextField>(find.descendant(of: find.byKey(const Key('composer')), matching: find.byType(TextField)));
    expect(field.enabled, isFalse);
  });

  testWidgets('about page links to the portfolio', (tester) async {
    await pumpApp(tester, Fakes(), '/about');
    expect(find.text('How it was built'), findsWidgets);
    expect(find.text('View the Portfolio'), findsOneWidget);
    expect(find.text('Demo site. Data resets nightly. Built by Jun Kit'), findsOneWidget);
  });
}
