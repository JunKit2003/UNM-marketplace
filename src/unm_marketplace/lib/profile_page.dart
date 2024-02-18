import 'dart:convert';
import 'dart:html';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
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
  Dio dio = DioSingleton.getInstance();
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileInfo();
  }

  Future<String> _getUsername() async {
    Dio dio = DioSingleton.getInstance();
    final response = await dio.post('http://${getHost()}:5000/api/getUsername');
    print(response.data['username']);
    return response.data['username'];
  }

  Future<void> _fetchProfileInfo() async {
    var url = 'http://${getHost()}:5000/api/profile';
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
      return Uint8List.fromList(response.data);
    } catch (e) {
      print('Error fetching image data: $e');
      return Uint8List(0);
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
          'http://${getHost()}:5000/api/UpdateProfilePhoto',
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  FutureBuilder<Uint8List>(
                    future: fetchImageData(
                      'http://${getHost()}:5000/images/$profilePicture',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Icon(Icons.error);
                      } else {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: snapshot.hasData
                              ? MemoryImage(snapshot.data!)
                              : AssetImage('assets/default_profile.jpg')
                                  as ImageProvider<Object>,
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _pickProfilePhoto(); // Wait for the user to pick a profile photo
                      await _updateProfilePicture(); // Submit the picked profile photo
                    },
                    child: Text('Change Profile Picture'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'First Name:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              firstName,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Last Name:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              lastName,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Email:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Username:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              username,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
