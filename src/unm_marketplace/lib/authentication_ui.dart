import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './authentication_provider.dart';

class AuthenticationUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    return MaterialApp(
      home: FutureBuilder(
        future: authProvider.initializePca(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Plugin example app'),
              ),
              body: Center(
                child: Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: authProvider.signIn,
                      child: Text('AcquireToken()'),
                    ),
                    ElevatedButton(
                      onPressed: authProvider.signIn,
                      child: Text('AcquireTokenSilently()'),
                    ),
                    ElevatedButton(
                      onPressed: authProvider.signOut,
                      child: Text('Logout'),
                    ),
                    Text('Your output here'),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Initialization error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
