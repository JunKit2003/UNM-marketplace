import 'package:flutter/material.dart';
import 'package:unm_marketplace/login_signup_page.dart';
import 'package:dio/dio.dart';

class AppDrawer extends StatelessWidget {
  // Add constructor if needed

  Future<void> logoutUser(BuildContext context) async {
    var dio = Dio();
    var url = 'http://localhost:5000/api/logout'; // Adjust as needed

    try {
      var response = await dio.post(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Successful Logout')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginSignupPage()),
        );
      }
    } on DioError catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error logging out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'University of Nottingham Malaysia Marketplace',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Listing'),
            onTap: () {
              // Handle the tap if necessary
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile Page'),
            onTap: () {
              // Handle the tap if necessary
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.cloud_upload),
            title: Text('Upload Listing'),
            onTap: () {
              // Handle the tap if necessary
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log out'),
            onTap: () {
              logoutUser(context);
            },
          ),
          // ... [other ListTile widgets]
        ],
      ),
    );
  }
}
