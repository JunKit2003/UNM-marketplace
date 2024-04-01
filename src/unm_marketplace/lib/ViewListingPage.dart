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

  Future<String> fetchProfilePhoto(String username) async {
    try {
      final profileResponse = await dioSingleton.post(
        'http://${getHost()}:5000/api/getProfilePhoto',
        data: {'username': username},
      );
      String profilePhotoUrl = profileResponse.data['profilePhotoUrl'];
      print('This is your profile photo URL: $profilePhotoUrl');
      return profilePhotoUrl;
    } catch (e) {
      print('Error fetching profile photo: $e');
      return ''; // Return an empty string if there's an error
    }
  }

  Future<String> getUsername() async {
    final response =
        await dioSingleton.post('http://${getHost()}:5000/api/getUsername');
    print(response.data['username']);
    return response.data['username'];
  }

  Future<String> getStreamToken() async {
    final response =
        await dio.post('http://${getHost()}:5000/api/getStreamToken');
    print(response.data['token']);
    return response.data['token'];
  }

  Future<void> fetchData() async {
    // Fetch the username
    username = await getUsername();

    // Fetch the profile photo and store the directory
    photoDirectory = await fetchProfilePhoto(username);
    print('---------------------PhotoDirectory: $photoDirectory');
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
        title: const Text('View Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16.0),
            if (_listingDetails != null) ...[
              Text(
                'Title: ${_listingDetails!['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text('Description: ${_listingDetails!['description']}'),
              const SizedBox(height: 8.0),
              Text(
                  'Condition: ${_listingDetails!['condition']}'), // Display the condition
              const SizedBox(height: 8.0),
              Text('Price: RM ${_listingDetails!['price']}'),
              const SizedBox(height: 8.0),
              Text(
                  'Contact Description: ${_listingDetails!['ContactDescription']}'),
              const SizedBox(height: 8.0),
              Text('Category: ${_listingDetails!['category']}'),
              const SizedBox(height: 8.0),
              Text(
                  'Posted Time: ${formatPostedDate(_listingDetails!['postedDate'])}'),
              const SizedBox(height: 8.0),
              Text('Posted By: ${_listingDetails!['PostedBy']}'),
              const SizedBox(height: 8.0),
              // Show the button only if the seller is not the current user
              if (_listingDetails!['PostedBy'] != username)
                ElevatedButton(
                  onPressed: () async {
                    if (!_loading) {
                      String token = await getStreamToken();
                      print('AMATOKEN: $token');
                      await connectUserToStream(token);
                      String sellerUsername = _listingDetails!['PostedBy'];
                      if (mounted) {
                        await createChannel(context, sellerUsername);
                      }
                    }
                  },
                  child: const Text('Chat with the seller'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
