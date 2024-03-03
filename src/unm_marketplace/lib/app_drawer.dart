import 'package:flutter/material.dart';
import 'package:unm_marketplace/listing_page.dart';
import 'package:unm_marketplace/login_signup_page.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/profile_page.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/upload_listing.dart';
import 'package:unm_marketplace/utils.dart';
import 'dart:typed_data';
import 'package:unm_marketplace/ListedAd.dart'; // Import the ListedAd.dart file

class AppDrawer extends StatefulWidget {
  @override
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
    final response = await dio.post('http://${getHost()}:5000/api/getUsername');
    print(response.data['username']);
    return response.data['username'];
  }

  Future<void> fetchData() async {
    // Fetch the username
    username = await getUsername();

    // Fetch the profile photo and store the directory
    photoDirectory = await fetchProfilePhoto(username);
    print('---------------------PhotoDirectory: $photoDirectory');

    setState(() {});
  }

  Future<String> fetchProfilePhoto(String username) async {
    try {
      final profileResponse = await dio.post(
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

  Future<Uint8List?> fetchImageData(String imageUrl) async {
    print(
        '--------------------------------------------------------------------');
    print(imageUrl);
    try {
      var response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        print('Unexpected status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching image data: $e');
      return null;
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    var url = 'http://${getHost()}:5000/api/logout'; // Adjust as needed

    try {
      var response = await dio.post(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Successful Logout')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginSignupPage()),
        );
      }
    } on DioError catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error logging out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: FutureBuilder<Uint8List?>(
              future: fetchImageData(
                'http://${getHost()}:5000/images/$photoDirectory',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Icon(Icons.error);
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
                            : const AssetImage('DefaultProfilePicture.jpg')
                                as ImageProvider<Object>,
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<String>(
                        future: getUsername(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'Welcome ${snapshot.data}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            );
                          } else {
                            return Text(
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
            leading: Icon(Icons.list),
            title: Text('Listing'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListingPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile Page'),
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
            leading: Icon(Icons.cloud_upload),
            title: Text('Upload Listing'),
            onTap: () {
              // Navigate to the UploadListingPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadListingPage()),
              );
            },
          ),

          // In the AppDrawer, where you navigate to the ListedAd page, provide the username parameter

          ListTile(
            leading: Icon(Icons.list_alt), // Icon for the new option
            title: Text('Listed Advertisements'), // Text for the new option
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
            leading: Icon(Icons.logout),
            title: Text('Log out'),
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
