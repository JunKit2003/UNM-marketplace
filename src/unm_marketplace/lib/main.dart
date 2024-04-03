import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_signup_page.dart';
import 'listing_page.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:unm_marketplace/Chat/app.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

StreamChatClient?
    globalStreamChatClient; // Global variable to hold the StreamChatClient instance

void main() async {
  // Initialize date formatting with the desired timezone (GMT+8)
  await initializeDateFormatting('en_US', null);

  // Initialize StreamChatClient
  final client = StreamChatClient(streamKey,
      logLevel: Level.INFO); // Set log level as needed);
  globalStreamChatClient = client; // Assign the client to the global variable

  runApp(
    MyApp(client: client),
  );
}

class MyApp extends StatefulWidget {
  final StreamChatClient client;
  const MyApp({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _authenticationResult;

  @override
  void initState() {
    super.initState();
    _authenticationResult = authenticateUser();
  }

  Future<bool> authenticateUser() async {
    Dio dio = DioSingleton.getInstance();
    var url =
        'http://${getHost()}/api/authenticate'; // Adjust the URL as per your server setup

    try {
      var response = await dio.post(url);

      // Handle successful response
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on DioException {
      return false;
    }
  }

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
          appBarTheme: const AppBarTheme(color: Colors.blue)),
      builder: (context, child) {
        return StreamChatCore(
          client: widget.client,
          child: child!,
        );
      },
      home: FutureBuilder<bool>(
        future: _authenticationResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          } else {
            if (snapshot.hasData && snapshot.data!) {
              return ListingPage(); // Navigate to ListingPage if authenticated
            } else {
              return LoginSignupPage(); // Navigate to LoginSignupPage if not authenticated
            }
          }
        },
      ),
    );
  }
}
