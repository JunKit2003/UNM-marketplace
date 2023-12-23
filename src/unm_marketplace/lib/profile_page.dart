import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

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
  Dio dio = DioSingleton.getInstance();

  @override
  void initState() {
    super.initState();
    _fetchProfileInfo();
  }

  Future<void> _fetchProfileInfo() async {
    var url =
        'http://${getHost()}:5000/api/profile'; // Replace with your server URL
    try {
      var response = await dio.post(url, data: {'username': widget.username});

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        setState(() {
          firstName = jsonResponse['firstName'];
          lastName = jsonResponse['lastName'];
          email = jsonResponse['email'];
        });
      } else {
        print('Failed to load profile');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('First Name: $firstName'),
            Text('Last Name: $lastName'),
            Text('Email: $email'),
          ],
        ),
      ),
    );
  }
}
