import 'dart:convert';
import 'dart:html';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:image_picker/image_picker.dart';

class UploadListingPage extends StatefulWidget {
  @override
  _UploadListingPageState createState() => _UploadListingPageState();
}

class _UploadListingPageState extends State<UploadListingPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  String title = '';
  String description = '';
  String price = '';
  String category = ''; // Updated category field
  String ContactDescription = '';
  String PostedBy = '';
  Dio dio = DioSingleton.getInstance();

  // Define a list of categories
  List<String> categories = [
    'Books',
    'Vehicles',
    'Property Rentals',
    'Home & Garden',
    'Electronics',
    'Hobbies',
    'Clothing & Accessories',
    'Family',
    'Entertainment',
    'Sports equipment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial value of category to the first item in the categories list
    category = categories.isNotEmpty ? categories[0] : '';
  }

  Future<String> _getUsername() async {
    Dio dio = DioSingleton.getInstance();
    final response = await dio.post('http://${getHost()}:5000/api/getUsername');
    print(response.data['username']);
    return response.data['username'];
  }

  Future<void> _pickListingPhoto() async {
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

  Future<int> _submitListingDetails() async {
    if (_formKey.currentState!.validate()) {
      // Print out the values before sending
      print('Submitting Listing Details:');
      print('Title: $title');
      print('Description: $description');
      print('Price: $price');
      print('Category: $category');
      print('ContactDescription : $ContactDescription');
      print('PostedBy : $PostedBy');

      // Send data
      var url = 'http://${getHost()}:5000/api/UploadListingDetails';
      try {
        final response = await dio.post(
          url,
          data: {
            'title': title,
            'description': description,
            'price': price,
            'category': category,
            'ContactDescription': ContactDescription,
            'PostedBy': await _getUsername(),
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          // Handle success
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Listing details uploaded successfully')));

          // Return the listing ID
          print(response.data['id']);
          return response.data['id'];
        } else {
          // Error response
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Listing details upload failed')));

          // Return a default value
          return -1;
        }
      } catch (e) {
        print('Error submitting listing details: $e');
        return -1;
      }
    }

    // Return a default value
    return -1;
  }

  Future<void> _submitListingPhoto(int listingId) async {
    if (_imageBytes != null) {
      try {
        FormData formData = FormData.fromMap({
          'listingPhoto':
              MultipartFile.fromBytes(_imageBytes!, filename: 'image.jpg'),
          'id': listingId,
        });

        var response = await dio.post(
          'http://${getHost()}:5000/api/UploadListingPhoto',
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
            SnackBar(content: Text('Listing photo uploaded successfully')),
          );
          Navigator.pop(context); // Navigate back to the previous screen
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing photo upload failed')),
          );
        }
      } catch (e) {
        print('Error submitting listing photo: $e');
      }
    } else {
      print('listingPhoto = null ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Listing'),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) {
                  setState(() {
                    title = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Container(
                  height: 200, // Adjust the height as needed
                  width: 200, // Adjust the width as needed
                  child: _imageBytes == null
                      ? Text('No image selected')
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.scaleDown,
                        ),
                ),
                onTap: _pickListingPhoto,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                onChanged: (value) {
                  setState(() {
                    price = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contact Description'),
                onChanged: (value) {
                  setState(() {
                    ContactDescription = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description on how the buyer will contact you';
                  }
                  return null;
                },
              ),
              // DropdownButtonFormField for category selection
              FormField<String>(
                builder: (FormFieldState<String> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      errorText: state.errorText,
                    ),
                    isEmpty: category == '',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        isDense: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            category = newValue!;
                            state.didChange(newValue);
                          });
                        },
                        items: categories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a category';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  // Inside an asynchronous function or method
                  int listingId = await _submitListingDetails();
                  if (listingId != -1) {
                    // Do something with the listingId
                    print('Listing ID: $listingId');
                    _submitListingPhoto(listingId);
                  } else {
                    // Handle the case where the submission failed
                    print('Failed to submit listing details');
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
