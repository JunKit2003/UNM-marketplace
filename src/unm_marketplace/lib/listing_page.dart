import 'package:flutter/material.dart';
import 'package:unm_marketplace/login_signup_page.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/app_drawer.dart'; // Ensure this path is correct

class ListingPage extends StatelessWidget {
  Future<void> logoutUser(BuildContext context) async {
    var dio = Dio();
    var url =
        'http://localhost:5000/api/logout'; // Adjust the URL as per your server setup

    try {
      var response = await dio.post(url);

      // Handle successful response
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Successful Logout')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginSignupPage()),
        );
      }
    } on DioError catch (e) {
      // Logout failed
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error logging out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listings'),
      ),
      drawer: AppDrawer(), // Use the AppDrawer widget here
      body: ListView.builder(
        itemCount: 10, // Placeholder item count
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.list),
            title: Text('Listing Item ${index + 1}'),
            // Add other item properties as needed
          );
        },
      ),
    );
  }
}
