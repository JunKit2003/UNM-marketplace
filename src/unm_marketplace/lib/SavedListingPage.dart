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

  Future<void> fetchUserSavedListings(String username) async {
    var url = '${getHost()}/api/GetUserSavedListings';

    try {
      var response =
          await dio.post(url, queryParameters: {'username': username});
      if (response.statusCode == 200) {
        // Extract saved listing IDs from the response
        List<dynamic> savedListingIds =
            List<dynamic>.from(response.data['savedListingIds']);

        // Ensure listingsID is not null
        listingsID ??= [];

        // Store the saved listing IDs in the listingsID list
        setState(() {
          listingsID.clear();
          listingsID.addAll(savedListingIds);
        });
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Number of Saved Listings: ${listingsID.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listings.length,
              itemBuilder: (context, index) {
                var listing = listings[index];
                // Check if the listing ID is contained in listingsID
                if (!listingsID.contains(listing['id'])) {
                  // If not contained, skip this listing
                  return SizedBox.shrink();
                }

                return Padding(
                  padding: EdgeInsets.all(8),
                  child: Card(
                    elevation: 3,
                    color: Colors.white, // Set background color of the Card
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      leading: SizedBox(
                        width: 150,
                        height: 100,
                        child: FutureBuilder<Uint8List>(
                          future: fetchImageData(
                            '${getHost()}/images/Listing/${listing['ImageID']}',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data == []) {
                              return Image.asset('assets/NoImageAvailable.jpg');
                            }

                            if (!snapshot.data!.isEmpty) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit
                                    .contain, // Maintain aspect ratio and cover the box
                              );
                            } else {
                              return Image.asset('assets/NoImageAvailable.jpg');
                            }
                          },
                        ),
                      ),
                      title: Text(
                        listing['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            listing['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Posted Date: ${formatPostedDate(listing['postedDate'])}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 120,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'RM${listing['price']}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
