import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:unm_marketplace/app_drawer.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

class ListingPage extends StatefulWidget {
  @override
  _ListingPageState createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  List<dynamic> listings = [];
  Dio dio = DioSingleton.getInstance();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchListings();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchListings();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchListings() async {
    var url = 'http://${getHost()}:5000/api/RetrieveListing';

    try {
      var response = await dio.post(url);
      if (response.statusCode == 200) {
        setState(() {
          listings = response.data['listings'];
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Dio Error: $e');
    }
  }

  Future<Uint8List> fetchImageData(String imageUrl) async {
    try {
      var response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(response.data);
    } catch (e) {
      print('Error fetching image data: $e');
      return Uint8List(0);
    }
  }

  // Method to format the posted date with GMT+8 timezone
  String formatPostedDate(String postedDate) {
    try {
      DateTime dateTime = DateTime.parse(postedDate).toUtc().add(Duration(
          hours:
              8)); // Parse the posted date string and convert to UTC, then add 8 hours
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      print('Error formatting posted date: $e');
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchListings,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: listings.isEmpty
          ? Center(child: Text('No listings available'))
          : ListView.builder(
              itemCount: listings.length,
              itemBuilder: (context, index) {
                var listing = listings[index];
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 100,
                      height: 100,
                      child: FutureBuilder<Uint8List>(
                        future: fetchImageData(
                            'http://${getHost()}:5000/images/${listing['ImageID']}'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Icon(Icons.error);
                          }
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    title: Text(listing['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing['description']),
                        Text('Price: \RM${listing['price']}'),
                        Text('Category: ${listing['category']}'),
                        Text('Posted By: ${listing['PostedBy']}'),
                        Text(
                            'Posted Date: ${formatPostedDate(listing['postedDate'])}'),
                      ],
                    ),
                    onTap: () {
                      // Handle tapping on the listing
                    },
                  ),
                );
              },
            ),
    );
  }
}
