import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/signup_page.dart';
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
        'http://${getHost()}/api/login'; // Adjust the URL as per your server setup

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
      appBar: AppBar(title: Text("Log In")),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 16, 38, 59),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 24, // Adjust the font size as needed
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty || !value.contains('@')
                                    ? 'Enter a valid email'
                                    : null,
                            onSaved: (value) => email = value!,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter your password' : null,
                            onSaved: (value) => password = value!,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitForm,
                            child: Text('Log In'),
                          ),
                          SizedBox(
                              height:
                                  10), // Add space between login button and text
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignupPage()),
                                );
                              },
                              child: 
                              const Text(
                                "Don't have an account? Register here",
                                style: TextStyle(
                                  shadows: [
                                    Shadow(
                                        color: Color.fromARGB(255, 16, 38, 59),
                                        offset: Offset(0, -4))
                                  ],
                                  color: Colors.transparent,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Color.fromARGB(255, 16, 38, 59),
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
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
