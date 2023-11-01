import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './authentication_provider.dart';
import './product_list_page.dart';
import './login_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the Marketplace App!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Check if the user is authenticated
                if (authProvider.isAuthenticated) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductListPage()));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              LoginPage())); // Redirect to the login page
                }
              },
              child: Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }
}
