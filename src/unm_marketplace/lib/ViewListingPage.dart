import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';
import 'package:unm_marketplace/Chat/UI/chat_screens.dart';
import 'package:unm_marketplace/Chat/app.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/main.dart';
import 'package:unm_marketplace/utils.dart';

class ViewListingPage extends StatefulWidget {
  final int listingId;

  const ViewListingPage({Key? key, required this.listingId}) : super(key: key);

  @override
  ViewListingPageState createState() => ViewListingPageState();
}

class ViewListingPageState extends State<ViewListingPage> {
  late Dio dio;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _listingDetails;
  Dio dioSingleton = DioSingleton.getInstance();
  String username = '';
  Uint8List? profilePhoto;
  String photoDirectory = '';

  @override
  void initState() {
    super.initState();
    dio = DioSingleton.getInstance();
    _fetchListingDetails(widget.listingId);
  }

  Future<void> _fetchListingDetails(int listingId) async {
    try {
      var response = await dio.post(
        '${getHost()}/api/RetrieveListing',
        queryParameters: {'id': listingId},
      );

      print('Listing details response: $response');

      if (response.statusCode == 200) {
        if (response.data['listings'] != null &&
            response.data['listings'].isNotEmpty) {
          var listing = response.data['listings'][0];
          setState(() {
            _listingDetails = listing;
          });

          var imageDataResponse = await dio.get(
            '${getHost()}/images/Listing/${listing['ImageID']}',
            options: Options(responseType: ResponseType.bytes),
          );

          print('Image data response: $imageDataResponse');

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

  Future<String> fetchProfilePhoto(String username) async {
    try {
      final profileResponse = await dioSingleton.post(
        '${getHost()}/api/getProfilePhoto',
        data: {'username': username},
      );
      String profilePhotoUrl = profileResponse.data['profilePhotoUrl'];
      print('Profile photo URL: $profilePhotoUrl');
      return profilePhotoUrl;
    } catch (e) {
      print('Error fetching profile photo: $e');
      return ''; // Return an empty string if there's an error
    }
  }

  Future<String> getUsername() async {
    final response = await dioSingleton.post('${getHost()}/api/getUsername');
    print('Username: ${response.data['username']}');
    return response.data['username'];
  }

  Future<String> getStreamToken() async {
    final response = await dio.post('${getHost()}/api/getStreamToken');
    print('Stream token: ${response.data['token']}');
    return response.data['token'];
  }

  Future<void> fetchData() async {
    // Fetch the username
    username = await getUsername();
    print('Fetched username: $username');

    // Fetch the profile photo and store the directory
    photoDirectory = await fetchProfilePhoto(username);
    print('Fetched photo directory: $photoDirectory');

    // Fetch the image URL from the directory
    setState(() {});
  }

  bool _loading = false;

  Future<void> connectUserToStream(String token) async {
    final client =
        globalStreamChatClient; // Access the global StreamChatClient instance
    if (client == null) {
      logger.e('StreamChatClient instance is null.');
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      String imageUrl = await fetchProfilePhoto(username);
      print('Image URL for stream: $imageUrl');
      // Check if the user is already connected
      if (client.state.currentUser != null) {
        return;
      }
      // User is not connected, proceed with connection
      await client.connectUser(
        User(
          id: 'username',
          extraData: {
            'name': username,
            'image': imageUrl,
          },
        ),
        token,
      );
    } on Exception catch (e, st) {
      logger.e('Could not connect user', error: e, stackTrace: st);
      // Log error when navigation fails
      logger.e('Navigation to ChatScreen failed');
    } finally {
      // Set the loading state to false regardless of success or failure
      setState(() {
        _loading = false;
      });
    }
  }

  Future<String> _getCurrentUsername() async {
    return await getUsername();
  }

  Future<void> createChannel(BuildContext context, sellerUsername) async {
    final core = StreamChatCore.of(context);
    final nav = Navigator.of(context);
    final channel = core.client.channel('messaging', extraData: {
      'members': [
        core.currentUser!.id,
        sellerUsername,
      ]
    });
    await channel.watch();

    nav.push(
      ChatScreens.routeWithChannel(channel),
    );
  }

  String formatPostedDate(String postedDate) {
    try {
      // Parse the posted date and adjust to Malaysia time
      DateTime postedDateTime =
          DateTime.parse(postedDate).add(const Duration(hours: 8));
      DateTime now = DateTime.now()
          .add(const Duration(hours: 8)); // Adjust for Malaysia time

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
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double maxWidth = constraints.maxWidth;
            bool isMobile = maxWidth < 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_imageBytes != null)
                  Container(
                    height: isMobile ? 200 : 400,
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                SizedBox(height: 16.0),
                if (_listingDetails != null) ...[
                  Container(
                    height: isMobile
                        ? null
                        : MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4.0,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _listingDetails!['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20.0 : 25.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _listingDetails!['condition'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'RM ${_listingDetails!['price'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20.0 : 25.0,
                                  ),
                                ),
                                Divider(height: 16.0),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontSize: isMobile ? 15.0 : 17.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _listingDetails!['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Divider(height: 16.0),
                                Text(
                                  'Contact Description :',
                                  style: TextStyle(
                                    fontSize: isMobile ? 15.0 : 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _listingDetails?['ContactDescription'] ??
                                      'N/A',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'Category:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 15.0 : 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _listingDetails!['category'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'Posted By:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 15.0 : 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _listingDetails!['PostedBy'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'Posted Time:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 15.0 : 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  formatPostedDate(
                                      _listingDetails!['postedDate'] ?? ''),
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.0 : 15.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: isMobile
                        ? MediaQuery.of(context).size.width * 0.3
                        : MediaQuery.of(context).size.width * 0.1,
                    width: isMobile
                        ? MediaQuery.of(context).size.width * 0.9
                        : null,
                    child: FractionallySizedBox(
                      widthFactor: isMobile ? 1.0 : 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.asset(
                            isMobile
                                ? 'assets/mobile_advertisement.png'
                                : 'assets/advertisement.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Show the button only if the seller is not the current user
                  FutureBuilder<String>(
                    future: _getCurrentUsername(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasData &&
                          snapshot.data != _listingDetails!['PostedBy']) {
                        return ElevatedButton(
                          onPressed: () async {
                            if (!_loading) {
                              String token = await getStreamToken();
                              await connectUserToStream(token);
                              String sellerUsername =
                                  _listingDetails!['PostedBy'];
                              if (mounted) {
                                await createChannel(context, sellerUsername);
                              }
                            }
                          },
                          child: const Text('Chat with the seller'),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
