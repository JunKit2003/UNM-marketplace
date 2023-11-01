import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './authentication_ui.dart';
import './authentication_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthenticationProvider(),
      child: AuthenticationUI(),
    ),
  );
}
