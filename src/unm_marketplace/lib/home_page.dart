// home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './authentication_provider.dart';
import './product_list_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // No need to get the AuthenticationProvider for now
    // final authProvider = Provider.of<AuthenticationProvider>(context);

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
                // Directly navigate to the ProductListPage without authentication
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListPage(),
                  ),
                );
              },
              child: Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }
}
