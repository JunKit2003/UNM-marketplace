import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './authentication_provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                authProvider.signIn(); // Trigger the login process
              },
              child: Text('Sign In with Microsoft'),
            ),
          ],
        ),
      ),
    );
  }
}
