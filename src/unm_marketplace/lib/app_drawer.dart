import 'package:flutter/material.dart';
import 'package:unm_marketplace/listing_page.dart';
import 'package:unm_marketplace/login_signup_page.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/profile_page.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/upload_listing.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:unm_marketplace/ListedAd.dart'; // Import the ListedAd.dart file

class AppDrawer extends StatelessWidget {
  // Add constructor if needed

  Future<String> getUsername() async {
    Dio dio = DioSingleton.getInstance();
    final response = await dio.post('http://${getHost()}:5000/api/getUsername');
    print(response.data['username']);
    return response.data['username'];
  }

  Future<void> logoutUser(BuildContext context) async {
    var dio = Dio();
    var url = 'http://${getHost()}:5000/api/logout'; // Adjust as needed

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListingPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile Page'),
            onTap: () async {
              String username = await getUsername();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(username: username)),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.cloud_upload),
            title: Text('Upload Listing'),
            onTap: () {
              // Navigate to the UploadListingPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadListingPage()),
              );
            },
          ),

          // In the AppDrawer, where you navigate to the ListedAd page, provide the username parameter

          ListTile(
            leading: Icon(Icons.list_alt), // Icon for the new option
            title: Text('Listed Advertisements'), // Text for the new option
            onTap: () async {
              String username = await getUsername(); // Fetch the username
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ListedAd(
                        username:
                            username)), // Provide the username to ListedAd
              );
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
