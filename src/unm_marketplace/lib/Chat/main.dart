import 'package:unm_marketplace/Chat/UI/screens.dart';
import 'package:unm_marketplace/Chat/UI/select_user_screen.dart';
import 'package:unm_marketplace/Chat/app.dart';
import 'package:unm_marketplace/Chat/theme.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

void main() {
  final client = StreamChatClient(streamKey);

  runApp(
    MyApp(client: client),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.client,
    }) : super(key: key);

  final StreamChatClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      title: 'Chatter',
      builder: (context, child) {
        return StreamChatCore(
          client: client, 
          child: child!,
        );
      },
      home: const SelectUserScreen(),
    );
  }
}