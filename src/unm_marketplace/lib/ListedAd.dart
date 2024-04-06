import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:unm_marketplace/EditListingPage.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:unm_marketplace/DioSingleton.dart';

class ListedAd extends StatefulWidget {
  final String username;

  const ListedAd({Key? key, required this.username}) : super(key: key);

  @override
  _ListedAdState createState() => _ListedAdState();
}

class _ListedAdState extends State<ListedAd> {
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
    var url = 'http://${getHost()}/api/RetrieveListing';

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

  Future<void> _deleteListing(dynamic listing) async {
    var url = 'http://${getHost()}/api/DeleteListing'; // Endpoint without ID

    try {
      var response = await dio.post(
        url,
        data: {'id': listing['id']}, // Include ID in the form data
      );

      if (response.statusCode == 200) {
        // Refresh the listings after deletion
        fetchListings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Advertisement deleted successfully.'),
          ),
        );
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete advertisement.'),
          ),
        );
      }
    } catch (e) {
      print('Dio Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete advertisement.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> userAds = listings
        .where((listing) => listing['PostedBy'] == widget.username)
        .toList();

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Listed Advertisements'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Number of Listed Advertisements: ${userAds.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: userAds.isEmpty
                ? Center(child: Text('You have not listed any advertisements.'))
                : ListView.builder(
                    itemCount: userAds.length,
                    itemBuilder: (context, index) {
                      var listing = userAds[index];
                      return Padding(
                        padding: EdgeInsets.all(8),
                        child: Card(
                          elevation: 3,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            leading: SizedBox(
                              width: 150,
                              height: 100,
                              child: FutureBuilder<Uint8List>(
                                future: fetchImageData(
                                  'http://${getHost()}/images/Listing/${listing['ImageID']}',
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
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
                            trailing: isSmallScreen
                                ? IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () {
                                      _showEditDeleteDialog(listing['id']);
                                    },
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditListingPage(
                                                  listingId: listing['id'],
                                                  onSubmitted: fetchListings,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 90,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit,
                                                    color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            _deleteListing(
                                                {'id': listing['id']});
                                          },
                                          child: Container(
                                            width: 100,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

  void _showEditDeleteDialog(int listingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Listing Options"),
          content: Text("Choose an option"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditListingPage(
                      listingId: listingId,
                      onSubmitted: fetchListings, // Pass the callback function
                    ),
                  ),
                );
              },
              child: Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                // Perform the delete operation
                _deleteListing({'id': listingId});
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
