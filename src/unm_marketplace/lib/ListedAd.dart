import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
    List<dynamic> userAds = listings
        .where((listing) => listing['PostedBy'] == widget.username)
        .toList();

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
      body: userAds.isEmpty
          ? Center(child: Text('You have not listed any advertisements.'))
          : ListView.builder(
              itemCount: userAds.length,
              itemBuilder: (context, index) {
                var listing = userAds[index];
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
