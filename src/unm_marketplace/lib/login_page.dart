import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './listing_page.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Future<void> loginUser(
      String email, String password, BuildContext context) async {
    Dio dio = DioSingleton.getInstance();
    var url =
        'http://${getHost()}:5000/api/login'; // Adjust the URL as per your server setup

    try {
      var response = await dio.post(url, data: {
        'email': email,
        'password': password,
      });

      // Handle successful response
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ListingPage()),
        );
      } else {
        // Handle unsuccessful login
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    } on DioError catch (e) {
      if (e.response != null && e.response!.statusCode == 401) {
        // Unauthorized or login failed
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid credentials')));
      } else {
        // Other types of Dio errors
        String errorMessage = e.response != null
            ? 'Login Failed: ${e.response!.statusCode}'
            : 'Error: ${e.message}';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      loginUser(email, password, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            constraints: BoxConstraints(
                maxWidth: 400), // Limit width for better readability
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
                    onSaved: (value) => email = value!,
                  ),
                  SizedBox(height: 20), // Add space between fields
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your password' : null,
                    onSaved: (value) => password = value!,
                  ),
                  SizedBox(height: 20), // Add space between fields and button
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
