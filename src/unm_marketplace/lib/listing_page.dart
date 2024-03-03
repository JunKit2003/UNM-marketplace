import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:unm_marketplace/app_drawer.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:unm_marketplace/ViewListingPage.dart';

class ListingPage extends StatefulWidget {
  @override
  _ListingPageState createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  List<dynamic> listings = [];
  List<dynamic> filteredListings = [];
  TextEditingController searchController = TextEditingController();
  String? selectedCategory = 'All';
  double? minPrice;
  double? maxPrice;
  Dio dio = DioSingleton.getInstance();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchListings();
    _timer = Timer.periodic(Duration(seconds: 300), (timer) {
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
          filteredListings = List.from(listings);
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Dio Error: $e');
    }
  }

  void searchListings(String query) {
    setState(() {
      filteredListings = listings
          .where((listing) =>
              listing['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void applyFilters() {
    setState(() {
      if (selectedCategory == 'All') {
        filteredListings = listings.where((listing) {
          bool matchesPriceRange =
              (minPrice == null || listing['price'] >= minPrice!) &&
                  (maxPrice == null || listing['price'] <= maxPrice!);
          return matchesPriceRange;
        }).toList();
      } else {
        filteredListings = listings.where((listing) {
          bool matchesCategory = selectedCategory == null ||
              listing['category'] == selectedCategory;
          bool matchesPriceRange =
              (minPrice == null || listing['price'] >= minPrice!) &&
                  (maxPrice == null || listing['price'] <= maxPrice!);
          return matchesCategory && matchesPriceRange;
        }).toList();
      }
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Listings',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: searchListings,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Filters'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                items: [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Books',
                                    child: Text('Books'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Vehicles',
                                    child: Text('Vehicles'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Property Rentals',
                                    child: Text('Property Rentals'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Home & Garden',
                                    child: Text('Home & Garden'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Electronics',
                                    child: Text('Electronics'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Hobbies',
                                    child: Text('Hobbies'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Clothing & Accessories',
                                    child: Text('Clothing & Accessories'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Family',
                                    child: Text('Family'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Entertainment',
                                    child: Text('Entertainment'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Sports equipment',
                                    child: Text('Sports equipment'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min Price',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    minPrice = double.tryParse(value);
                                  });
                                },
                              ),
                              TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max Price',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    maxPrice = double.tryParse(value);
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                applyFilters();
                                Navigator.pop(context);
                              },
                              child: Text('Apply'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCategory = 'All';
                                  minPrice = null;
                                  maxPrice = null;
                                });
                                applyFilters();
                                Navigator.pop(context);
                              },
                              child: Text('Clear Filters'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Filter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredListings.isEmpty
                ? Center(child: Text('No listings available'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600 ? 0.75 : 1.0,
                    ),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      var listing = filteredListings.reversed.toList()[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewListingPage(
                                listingId: listing[
                                    'id'], // Pass the listing ID to ViewListingPage
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FutureBuilder<Uint8List>(
                                  future: fetchImageData(
                                      'http://${getHost()}:5000/images/${listing['ImageID']}'),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return Icon(Icons.error);
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit
                                          .contain, // Adjust the fit property
                                      width: double.infinity,
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing['title'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Price: RM ${listing['price']}'),
                                  ],
                                ),
                              ),
                            ],
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
}

void main() {
  runApp(MaterialApp(
    home: ListingPage(),
  ));
}
