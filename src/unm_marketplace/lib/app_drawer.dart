// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:unm_marketplace/listing_page.dart';
import 'package:unm_marketplace/login_signup_page.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/main.dart';
import 'package:unm_marketplace/profile_page.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/upload_listing.dart';
import 'package:unm_marketplace/utils.dart';
import 'dart:typed_data';
import 'package:unm_marketplace/ListedAd.dart'; // Import the ListedAd.dart file
import 'package:unm_marketplace/Chat/UI/home_screen.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';
import 'package:logger/logger.dart' as log;

const apiKey = 'adqmr32mfsg4';
var logger = log.Logger();

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String username = '';
  Uint8List? profilePhoto;
  Dio dio = DioSingleton.getInstance(); // Ensure you have this line
  String photoDirectory = '';
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<String> getUsername() async {
    final response = await dio.post('${getHost()}/api/getUsername');
    return response.data['username'];
  }

  Future<String> getStreamToken() async {
    final response = await dio.post('${getHost()}/api/getStreamToken');
    return response.data['token'];
  }

  Future<void> fetchData() async {
    // Fetch the username
    username = await getUsername();

    // Fetch the profile photo and store the directory
    photoDirectory = await fetchProfilePhoto(username);

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
        // User is already connected, no need to connect again
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
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

      // Navigate to the home screen after successful connection
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on Exception catch (e, st) {
      logger.e('Could not connect user', error: e, stackTrace: st);
      // Log error when navigation fails
      logger.e('Navigation to HomeScreen failed');
    } finally {
      // Set the loading state to false regardless of success or failure
      setState(() {
        _loading = false;
      });
    }
  }

  Future<String> fetchProfilePhoto(String username) async {
    try {
      final profileResponse = await dio.post(
        '${getHost()}/api/getProfilePhoto',
        data: {'username': username},
      );
      String profilePhotoUrl = profileResponse.data['profilePhotoUrl'];
      return profilePhotoUrl;
    } catch (e) {
      return ''; // Return an empty string if there's an error
    }
  }

  Future<Uint8List?> fetchImageData(String imageUrl) async {
    try {
      var response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    var url = '${getHost()}/api/logout'; // Adjust as needed

    try {
      var response = await dio.post(url);

      if (response.statusCode == 200) {
        // Clear StreamChat client's state upon successful logout
        final client = globalStreamChatClient;
        if (client != null) {
          await client.disconnectUser();
        }

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Successful Logout')));
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginSignupPage()),
          (route) => false, // Clear the navigation stack
        );
      }
    } on DioException {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error logging out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: FutureBuilder<Uint8List?>(
              future: fetchImageData(
                '${getHost()}/images/ProfilePhoto/$photoDirectory',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container();
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error);
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: snapshot.hasData
                            ? MemoryImage(snapshot.data!)
                            : const AssetImage(
                                    'assets/DefaultProfilePicture.jpg')
                                as ImageProvider<Object>,
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<String>(
                        future: getUsername(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'Welcome ${snapshot.data}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            );
                          } else {
                            return const Text(
                              'Welcome User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Listing'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Page'),
            onTap: () async {
              String username = await getUsername();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(username: username)),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Upload Listing'),
            onTap: () {
              // Navigate to the UploadListingPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadListingPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.list_alt), // Icon for the new option
            title:
                const Text('Listed Advertisements'), // Text for the new option
            onTap: () async {
              String username = await getUsername(); // Fetch the username
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ListedAd(
                        username:
                            username)), // Provide the username to ListedAd
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            onTap: () async {
              // Ensure that the loading state is not set to true again if it's already loading
              if (!_loading) {
                String token = await getStreamToken();
                await connectUserToStream(token);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              logoutUser(context);
            },
          ),
          // ... [other ListTile widgets]
        ],
      ),
    );
  }
}
