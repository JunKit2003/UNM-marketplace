import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  final String username;

  ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

  Future<void> _updateProfilePicture() async {
    // Implement the logic to update the profile picture here
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
              child: MouseRegion(
                onEnter: (_) => setState(() => isHovering = true),
                onExit: (_) => setState(() => isHovering = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isHovering
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: GestureDetector(
                    onTap: _updateProfilePicture,
                    child: FutureBuilder<Uint8List>(
                      future: fetchImageData(
                        'http://${getHost()}:5000/images/$profilePicture',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                  ),
                ),
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
