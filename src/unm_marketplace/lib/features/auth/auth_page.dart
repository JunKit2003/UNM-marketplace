import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.from});
  final String? from;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login')));
}
