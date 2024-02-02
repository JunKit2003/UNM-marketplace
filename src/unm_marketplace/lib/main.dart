import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_signup_page.dart';

void main() async {
  // Initialize date formatting with the desired timezone (GMT+8)
  await initializeDateFormatting('en_US', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginSignupPage(),
    );
  }
}
