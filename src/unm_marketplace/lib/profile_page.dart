import 'package:flutter/material.dart';
import 'package:unm_marketplace/login_signup_page.dart';

class ProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final int accountId;

  ProfilePage(
      {Key? key,
      required this.firstName,
      required this.lastName,
      required this.accountId})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'University of Nottingham Malaysia Marketplace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
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
                
                // Navigate back to LoginSignupPage
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginSignupPage()));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Name: ${widget.firstName} ${widget.lastName}',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Account ID: ${widget.accountId}',
                style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
