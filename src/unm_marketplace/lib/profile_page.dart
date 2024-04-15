import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/UpdatePassword.dart';
import 'package:unm_marketplace/utils.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _imageBytes;
  String firstName = '';
  String lastName = '';
  String email = '';
  String username = '';
  String profilePicture = ''; // Changed to camelCase for consistency
  String phoneNumber = ''; // Added phone number
  Dio dio = DioSingleton.getInstance();
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileInfo();
  }

  Future<void> _fetchProfileInfo() async {
    var url = '${getHost()}/api/profile';
    try {
      var response = await dio.post(url, data: {'username': widget.username});

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        setState(() {
          firstName = jsonResponse['firstName'];
          lastName = jsonResponse['lastName'];
          email = jsonResponse['email'];
          username = jsonResponse['username'];
          profilePicture =
              jsonResponse['ProfilePicture']; // Corrected variable name
          phoneNumber = jsonResponse['phone_number']; // Retrieve phone number
        });
      } else {
        print('Failed to load profile');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<Uint8List> fetchImageData(String imageUrl) async {
    try {
      var response = await dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        // Handle other status codes if needed
        print('Unexpected status code: ${response.statusCode}');
        return Uint8List(0); // Return an empty Uint8List as a fallback
      }
    } catch (e) {
      print('Error fetching image data: $e');
      return Uint8List(0); // Return an empty Uint8List as a fallback
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      print('Error picking listing photo: $e');
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_imageBytes != null) {
      try {
        FormData formData = FormData.fromMap({
          'profilePhoto':
              MultipartFile.fromBytes(_imageBytes!, filename: 'profile.jpg'),
          'username': username,
        });

        var response = await dio.post(
          '${getHost()}/api/UpdateProfilePhoto',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        if (response.statusCode == 200) {
          // Handle success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile photo uploaded successfully')),
          );
          // You might want to refresh the profile page after successful upload
          _fetchProfileInfo();
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile photo upload failed')),
          );
        }
      } catch (e) {
        print('Error updating profile photo: $e');
      }
    } else {
      print('profilePhoto is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    //double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wpp2.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: [
                        profilePicture.isEmpty
                            ? CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: AssetImage(
                                    'assets/DefaultProfilePicture.jpg'),
                              )
                            : FutureBuilder<Uint8List>(
                                future: fetchImageData(
                                    '${getHost()}/images/ProfilePhoto/$profilePicture'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Icon(Icons.error);
                                  } else {
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.lightBlue[400]!,
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 3,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        radius: 80,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: snapshot.hasData
                                            ? MemoryImage(snapshot.data!)
                                            : AssetImage(
                                                    'assets/DefaultProfilePicture.jpg')
                                                as ImageProvider<Object>,
                                      ),
                                    );
                                  }
                                },
                              ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await _pickProfilePhoto();
                                await _updateProfilePicture();
                              },
                              child: Text('Change Profile Picture'),
                            ),
                            SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdatePasswordPage(username: username),
                                  ),
                                );
                              },
                              child: Text('Change Password'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileItem(
                              'First Name', firstName, screenHeight),
                          _buildProfileItem(
                              'Last Name', lastName, screenHeight),
                          _buildProfileItem('Email', email, screenHeight),
                          _buildProfileItem('Username', username, screenHeight),
                          _buildProfileItem(
                              'Phone Number', phoneNumber, screenHeight),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: screenHeight * 0.02),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: screenHeight * 0.018),
        ),
        Divider(),
      ],
    );
  }
}
