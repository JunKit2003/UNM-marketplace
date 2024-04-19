import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:unm_marketplace/ViewListingPage.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:unm_marketplace/DioSingleton.dart';

class SavedListingPage extends StatefulWidget {
  final String username;

  const SavedListingPage({Key? key, required this.username}) : super(key: key);

  @override
  _SavedListingPageState createState() => _SavedListingPageState();
}

class _SavedListingPageState extends State<SavedListingPage> {
  List<dynamic> listingsID = [];
  List<dynamic> listings = [];
  Dio dio = DioSingleton.getInstance();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchUserSavedListings(widget.username);
    await fetchListings();
  }

  Future<void> fetchListings() async {
    var url = '${getHost()}/api/RetrieveListing';

    try {
      var response = await dio.post(url, queryParameters: {'id': listingsID});
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

  Future<void> fetchUserSavedListings(String username) async {
    var url = '${getHost()}/api/getUserSavedListings';

    try {
      var response =
          await dio.post(url, queryParameters: {'username': username});
      if (response.statusCode == 200) {
        // Extract saved listing IDs from the response
        List<String> savedListingIds =
            List<String>.from(response.data['savedListingIds']);

        // Store the saved listing IDs in the listings list
        listingsID.clear();
        listingsID.addAll(savedListingIds);
      } else {
        // Handle error responses
        print('Error fetching saved listings: ${response.statusCode}');
      }
    } catch (e) {
      // Handle Dio errors
      print('Dio Error fetching saved listings: $e');
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

  String formatPostedDate(String postedDate) {
    try {
      DateTime dateTime =
          DateTime.parse(postedDate).toUtc().add(Duration(hours: 8));
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
        title: Text('Saved Listings'),
      ),
      body: ListView.builder(
        itemCount: listings.length,
        itemBuilder: (context, index) {
          var listing = listings[index];
          return ListTile(
            title: Text(listing[
                'title']), // Assuming 'title' is a key in your listing data
            subtitle: Text(formatPostedDate(listing[
                'postedDate'])), // Assuming 'postedDate' is a key in your listing data
            leading: FutureBuilder(
              future: fetchImageData(
                  '${getHost()}/images/Listing/${listing['ImageID']}'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Icon(Icons.error);
                } else {
                  return CircleAvatar(
                    backgroundImage: MemoryImage(snapshot.data as Uint8List),
                  );
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewListingPage(listingId: listing['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
