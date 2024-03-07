import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_signup_page.dart';
import 'package:unm_marketplace/Chat/app.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

void main() async {
  // Initialize date formatting with the desired timezone (GMT+8)
  await initializeDateFormatting('en_US', null);

  // Initialize StreamChatClient
  final client = StreamChatClient(streamKey);

  runApp(
    MultiApp(client: client),
  );
}

class MultiApp extends StatelessWidget {
  const MultiApp({
    Key? key,
    required this.client,
  }) : super(key: key);

  final StreamChatClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black, // Your specific color
          onPrimary: Colors.white, // Text color on top of the primary color
          secondary: Colors.white, // Your specific color
          onSecondary:
              Colors.white, // Text color on top of the secondary color
          error: Colors.red, // Default
          onError: Colors.red, // Text color on top of the error color
          background: Colors.white, // Default background color
          onBackground: Colors.black, // Text color on the background
          surface: Colors.white, // Default surface color
          onSurface: Colors.black, // Text color on the surface
        ),
        appBarTheme: const AppBarTheme(color: Colors.blue),
      ),
      builder: (context, child) {
        return StreamChatCore(
          client: client,
          child: child!,
        );
      },
      home: const MultiAppHome(),
    );
  }
}

class MultiAppHome extends StatelessWidget {
  const MultiAppHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoginSignupPage(); // Use your desired home screen
  }
}

