import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Import CarouselSlider
import 'package:unm_marketplace/app_drawer.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/profile_page.dart';
import 'package:unm_marketplace/utils.dart';
import 'upload_listing.dart';

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
      body: Center(
        child: Container(
          width: 1400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 900,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: Colors.black, width: 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 4.0),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                border: InputBorder.none,
                              ),
                              onChanged: searchListings,
                            ),
                          ),
                        ],
                      ),
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
                                      child:
                                          Text('Clothing & Accessories'),
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
              SizedBox(height: 20),
              CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  pauseAutoPlayOnTouch: true,
                  enableInfiniteScroll: true,
                  viewportFraction: 0.8,
                ),
                items: [
                  'assets/images.png', // Path to your poster image
                ].map((image) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: Colors.black, width: 5.0),
                        ),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Buttons for each category
             SizedBox(
                height: 95, // Adjust the height as needed
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton(
                    category: 'All',
                    imagePath: 'assets/all_image.png', // Change the image path as needed
                  ),
                  _buildCategoryButton(
                    category: 'Sports equipment',
                    imagePath: 'assets/SEimage.png',
                  ),
                    _buildCategoryButton(
                      category: 'Books',
                      imagePath: 'assets/books_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Vehicles',
                      imagePath: 'assets/vehicles_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Property Rentals',
                      imagePath: 'assets/property_rentals_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Home & Garden',
                      imagePath: 'assets/home_garden_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Electronics',
                      imagePath: 'assets/electronics_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Hobbies',
                      imagePath: 'assets/hobbies_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Clothing & Accessories',
                      imagePath: 'assets/clothing_accessories_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Family',
                      imagePath: 'assets/family_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Entertainment',
                      imagePath: 'assets/entertainment_image.png',
                    ),
                    _buildCategoryButton(
                      category: 'Other',
                      imagePath: 'assets/other_image.png',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: filteredListings.isEmpty
                      ? Center(child: Text('No listings available'))
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 600 ? 4 : 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio:
                                MediaQuery.of(context).size.width > 600
                                    ? 0.75
                                    : 1.0,
                          ),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            var listing =
                                filteredListings.reversed.toList()[index];
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return ListingDetailDialog(
                                        listing: listing);
                                  },
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
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          if (snapshot.hasError ||
                                              !snapshot.hasData) {
                                            return Icon(Icons.error);
                                          }
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      child: Container(
        height: 60.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // Handle home button press
              },
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadListingPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(username: '',)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
Widget _buildCategoryButton({required String category, required String imagePath}) {
  // Split the category name at the first space
  List<String> categoryNameParts = category.split(' ');
  
  return Expanded(
    child: Container(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                selectedCategory = category;
              });
              applyFilters();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          SizedBox(height: 5), // Add some space between the button and the label
          Column(
            children: [
              Text(
                categoryNameParts[0], // Display the first part of the category name
                textAlign: TextAlign.center, // Align the text to center
                style: TextStyle(fontSize: 12), // Adjust the font size as needed
              ),
              Text(
                categoryNameParts.sublist(1).join(' '), // Display the remaining parts of the category name
                textAlign: TextAlign.center, // Align the text to center
                style: TextStyle(fontSize: 12), // Adjust the font size as needed
              ),
            ],
          ),
        ],
      ),
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

class ListingDetailDialog extends StatelessWidget {
  final dynamic listing;

  ListingDetailDialog({required this.listing});
  
@override
Widget build(BuildContext context) {
  return Dialog(
    child: Container(
      width: MediaQuery.of(context).size.width * 0.3, // Adjust the width as needed
      height: MediaQuery.of(context).size.height * 0.6, // Adjust the height as needed
      child: SingleChildScrollView( // Wrap the content in SingleChildScrollView
        physics: AlwaysScrollableScrollPhysics(), // Set physics to AlwaysScrollableScrollPhysics
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3, // Adjust the height of the image box
              child: Image.network(
                'http://${getHost()}:5000/images/${listing['ImageID']}',
                fit: BoxFit.contain,
              ),
            ),
            ListTile(
              title: Text(
                listing['title'],
                style: TextStyle(
                  fontSize: 32, // Adjust the font size as needed
                  fontWeight: FontWeight.bold, // Make the text bold
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                  Text('${listing['description']}'),
                  Text(
                    'Category: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                  Text('${listing['category']}'),
                  Text(
                    'Posted By: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                  Text('${listing['PostedBy']}'),
                  Text(
                    'Price: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                  Text('RM ${listing['price']}'),
                  Text(
                    'Posted Date: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                  Text(
                    '${formatPostedDate(listing['postedDate'])}',
                  ),
                ],
              ),
            ),
 Container(
  alignment: Alignment.center,
  child: FloatingActionButton(
    onPressed: () {
      Navigator.pop(context);
    },
    child: Container(
      width: 50, // Adjust width as needed to match the image size
      height: 50, // Adjust height as needed to match the image size
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0), // Set border radius
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0), // Clip rounded corners
        child: Image.asset(
          'assets/close_image.png', // Replace with the path to your close button image
          fit: BoxFit.fill, // Make the image fill the button
        ),
      ),
    ),
    backgroundColor: Colors.transparent, // Set background color to transparent
    elevation: 0, // Remove elevation
    highlightElevation: 0, // Remove elevation when button is pressed
  ),
),


          ],
        ),
      ),
    ),
  );
}


  String formatPostedDate(String postedDate) {
    try {
      DateTime postedDateTime =
          DateTime.parse(postedDate).toUtc().add(Duration(hours: 8));
      Duration difference = DateTime.now().difference(postedDateTime);
      String differenceString = '';

      if (difference.inDays > 0) {
        differenceString = '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        differenceString = '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        differenceString = '${difference.inMinutes} minutes ago';
      } else {
        differenceString = 'Just now';
      }

      return '${DateFormat('yyyy-MM-dd HH:mm:ss').format(postedDateTime)} ($differenceString)';
    } catch (e) {
      print('Error formatting posted date: $e');
      return 'Invalid Date';
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: ListingPage(),
  ));
}
