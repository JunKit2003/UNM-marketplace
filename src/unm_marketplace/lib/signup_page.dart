import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/login_page.dart';
import 'package:unm_marketplace/utils.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String username = '';
  String email = '';
  String phone_number = '';
  String password = '';

  Future<void> registerUser(String firstName, String lastName, String email,
      String phone_number, String password, BuildContext context) async {
    var url = '${getHost()}/api/signup'; // URL for local server
    Dio dio = DioSingleton.getInstance();

    try {
      print(firstName);
      print(lastName);
      print(email);
      print(phone_number);
      print(password);

      var response = await dio.post(url,
          data: {
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
            'email': email,
            'phone_number': phone_number,
            'password': password,
          },
          options: Options(headers: {"Content-Type": "application/json"}));

      print(response.data);

      if (response.statusCode == 200) {
        // Success response
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Signup Successful')));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // Error response
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Signup Failed')));
      }
    } on DioException catch (e) {
      // Handling DioError separately
      if (e.response?.statusCode == 400) {
        String errorMessage = e.response?.data['message'] ?? 'Signup Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An Unknown Error has occurred')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An Unknown Error has occurred')));
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      registerUser(firstName, lastName, email, phone_number, password, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    return Scaffold(
      //appBar: AppBar(title: const Text("Signup")),
      body: Container(
        decoration: BoxDecoration(
            //color: Color.fromARGB(255, 16, 38, 59),
            image: DecorationImage(
          image: AssetImage('assets/wpp1.jpg'),
          fit: BoxFit.cover,
        )),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: const BoxConstraints(
                  maxWidth: 400), // Limit width for better readability
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.04),
                    child: Image.asset(
                        'assets/logo.jpg'), // Image positioned above the "Log In" text
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 24, // Adjust the font size as needed
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
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
                            decoration:
                                InputDecoration(labelText: 'First Name'),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your first name'
                                : null,
                            onSaved: (value) => firstName = value!,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Last Name'),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your last name'
                                : null,
                            onSaved: (value) => lastName = value!,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Username'),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a username'
                                : null,
                            onSaved: (value) => username = value!,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty || !value.contains('@')
                                    ? 'Please enter a valid email'
                                    : null,
                            onSaved: (value) => email = value!,
                          ),
                          TextFormField(
                            decoration:
                                InputDecoration(labelText: 'Phone Number'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                            onSaved: (value) => phone_number = value!,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a password'
                                : null,
                            onSaved: (value) => password = value!,
                          ),
                          SizedBox(
                              height:
                                  20), // Add space between fields and button
                          ElevatedButton(
                            onPressed: _submitForm,
                            child: Text('Sign Up'),
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
                                      builder: (context) => LoginPage()),
                                );
                              },
                              child: const Text(
                                "Already have an account? Log in here",
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
