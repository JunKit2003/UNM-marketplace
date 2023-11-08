import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadListingPage extends StatelessWidget {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Replace with your local IP and path to the PHP script
  final String apiEndpoint =
      'http://10.0.2.2/unm_marketplace_api/add_listing.php';

  Future<void> _uploadListing() async {
    final response = await http.post(
      Uri.parse(apiEndpoint),
      body: {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        // Handle successful upload
        print('Listing uploaded successfully');
      } else {
        // Handle error
        print('Failed to upload listing');
      }
    } else {
      // Handle network error
      print('Network error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _uploadListing,
              child: Text('Upload Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
