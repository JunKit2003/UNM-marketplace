import 'package:flutter/material.dart';
import 'upload_listing_page.dart'; // Make sure this import is correct

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UploadListingPage(), // Set UploadListingPage as the home widget
    );
  }
}
