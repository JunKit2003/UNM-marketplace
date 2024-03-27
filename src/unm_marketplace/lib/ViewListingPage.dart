import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

class ViewListingPage extends StatefulWidget {
  final int listingId;

  ViewListingPage({required this.listingId});

  @override
  _ViewListingPageState createState() => _ViewListingPageState();
}

class _ViewListingPageState extends State<ViewListingPage> {
  late Dio dio;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _listingDetails;

  @override
  void initState() {
    super.initState();
    dio = DioSingleton.getInstance();
    _fetchListingDetails(widget.listingId);
  }

  Future<void> _fetchListingDetails(int listingId) async {
    try {
      var response = await dio.post(
        'http://${getHost()}:5000/api/RetrieveListing',
        queryParameters: {'id': listingId},
      );

      if (response.statusCode == 200) {
        if (response.data['listings'] != null &&
            response.data['listings'].isNotEmpty) {
          var listing = response.data['listings'][0];
          setState(() {
            _listingDetails = listing;
          });

          var imageDataResponse = await dio.get(
            'http://${getHost()}:5000/images/Listing/${listing['ImageID']}',
            options: Options(responseType: ResponseType.bytes),
          );

          if (imageDataResponse.statusCode == 200) {
            setState(() {
              _imageBytes = Uint8List.fromList(imageDataResponse.data);
            });
          } else {
            print('Failed to fetch image data');
          }
        } else {
          print('No listing found');
        }
      } else {
        print('Failed to fetch listing details');
      }
    } catch (e) {
      print('Error fetching listing details: $e');
    }
  }

  String formatPostedDate(String postedDate) {
    try {
      // Parse the posted date and adjust to Malaysia time
      DateTime postedDateTime =
          DateTime.parse(postedDate).add(Duration(hours: 8));
      DateTime now =
          DateTime.now().add(Duration(hours: 8)); // Adjust for Malaysia time

      Duration difference = now.difference(postedDateTime);
      String differenceString = '';

      if (difference.inDays > 0) {
        differenceString =
            '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        differenceString =
            '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        differenceString =
            '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        differenceString = 'Just now';
      }

      // Format the posted date with the time difference
      return '${DateFormat('yyyy-MM-dd HH:mm:ss').format(postedDateTime)} ($differenceString)';
    } catch (e) {
      print('Error formatting posted date: $e');
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Listing'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageBytes != null)
              Container(
                height: 400, // Set a fixed height for the container
                alignment: Alignment.center, // Align the image to center
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain, // Set fit property to contain
                ),
              ),
            SizedBox(height: 16.0),
            if (_listingDetails != null) ...[
              Text(
                'Title: ${_listingDetails!['title']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('Description: ${_listingDetails!['description']}'),
              SizedBox(height: 8.0),
              Text(
                  'Condition: ${_listingDetails!['condition']}'), // Display the condition
              SizedBox(height: 8.0),
              Text('Price: RM ${_listingDetails!['price']}'),
              SizedBox(height: 8.0),
              Text(
                  'Contact Description: ${_listingDetails!['ContactDescription']}'),
              SizedBox(height: 8.0),
              Text('Category: ${_listingDetails!['category']}'),
              SizedBox(height: 8.0),
              Text(
                  'Posted Time: ${formatPostedDate(_listingDetails!['postedDate'])}'),
              SizedBox(height: 8.0),
              Text('Posted By: ${_listingDetails!['PostedBy']}'),
            ],
          ],
        ),
      ),
    );
  }
}
