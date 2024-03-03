import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
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
    var url = 'http://${getHost()}:5000/api/signup'; // URL for local server
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
      } else {
        // Error response
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Signup Failed')));
      }
    } on DioError catch (e) {
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
    return Scaffold(
      appBar: AppBar(title: Text("Signup")),
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
                    decoration: InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your first name' : null,
                    onSaved: (value) => firstName = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Last Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your last name' : null,
                    onSaved: (value) => lastName = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a username' : null,
                    onSaved: (value) => username = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@')
                        ? 'Please enter a valid email'
                        : null,
                    onSaved: (value) => email = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Phone Number'),
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
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a password' : null,
                    onSaved: (value) => password = value!,
                  ),
                  SizedBox(height: 20), // Add space between fields and button
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Sign Up'),
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
