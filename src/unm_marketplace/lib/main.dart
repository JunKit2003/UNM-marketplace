import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_signup_page.dart';

void main() async {
  // Initialize date formatting with the desired timezone (GMT+8)
  await initializeDateFormatting('en_US', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      home: LoginSignupPage(),
    );
  }
}
