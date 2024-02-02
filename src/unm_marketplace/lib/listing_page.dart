import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/app_drawer.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

class ListingPage extends StatefulWidget {
  @override
  _ListingPageState createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  List<dynamic> listings = [];

  @override
  void initState() {
    super.initState();
    fetchListings(); // Call fetchListings() when the widget is initialized
  }

  Future<void> fetchListings() async {
    var url = 'http://${getHost()}:5000/api/RetrieveListing';
    Dio dio = DioSingleton.getInstance();

    try {
      var response = await dio.post(url);
      if (response.statusCode == 200) {
        setState(() {
          listings = response.data['listings'];
        });
      } else {
        // Handle error responses
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle Dio errors
      print('Dio Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
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
                      width: 100, // Set the desired width of the leading widget
                      height:
                          100, // Set the desired height of the leading widget
                      child: Image.network(
                        listing['ImageURL'],
                        fit: BoxFit.cover,
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
                        Text('Posted Date: ${listing['postedDate']}'),
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
