import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart'; // Import the dotted_border package

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
  String ContactDescription = 'Message me with the button below !';
  String PostedBy = '';
  String condition = ''; // New field for item condition
  Dio dio = DioSingleton.getInstance();
  List<String> categories = [];
  List<String> conditions = [
    'Brand new',
    'Like new',
    'Lightly used',
    'Well used',
    'Heavily used'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      var response = await dio.post('${getHost()}/api/getCategories');

      if (response.statusCode == 200) {
        setState(() {
          categories = List<String>.from(response.data['categories']);
          category = categories.isNotEmpty ? categories[0] : '';
        });
      } else {
        print('Failed to fetch categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<String> _getUsername() async {
    Dio dio = DioSingleton.getInstance();
    final response = await dio.post('${getHost()}/api/getUsername');
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
      // Send data
      var url = '${getHost()}/api/UploadListingDetails';
      try {
        final response = await dio.post(
          url,
          data: {
            'title': title,
            'description': description,
            'condition': condition, // Include condition in data payload
            'price': double.tryParse(price),
            'ContactDescription': ContactDescription,
            'category': category,
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
          '${getHost()}/api/UploadListingPhoto',
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
        backgroundColor: Colors.lightBlue,
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: MediaQuery.of(context).size.width < 600
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color.fromARGB(255, 133, 188, 240)),
              ),
              child: InkWell(
                onTap: _pickListingPhoto,
                child: DottedBorder(
                  color: Colors.transparent, // Transparent color for the dots
                  strokeWidth: 1,
                  borderType: BorderType.RRect,
                  radius: Radius.circular(8),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: _imageBytes == null
                          ? Text('No image selected')
                          : Image.memory(
                              _imageBytes!,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: DottedBorder(
              dashPattern: [6, 3],
              color: const Color.fromARGB(255, 133, 188, 240),
              strokeWidth: 1,
              borderType: BorderType.RRect,
              radius: Radius.circular(8),
              child: Container(
                height: 400,
                width: 800,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _pickListingPhoto,
                  child: Center(
                    child: _imageBytes == null
                        ? Text('No image selected')
                        : SizedBox(
                            height: 300,
                            width: 700,
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'Enter the title of your listing',
            labelStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: TextStyle(
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(color: Colors.black),
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
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          constraints:
              BoxConstraints(minHeight: 300, maxHeight: double.infinity),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            border: Border.all(color: Colors.black),
          ),
          child: TextFormField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Enter the description of your listing',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.0),
            ),
            style: TextStyle(color: Colors.black),
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
        ),
        SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Condition',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: conditions.map((String value) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: SizedBox(
                      height: 48.0,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            condition = value;
                          });
                        },
                        child: Center(
                          child: Text(
                            value,
                            textAlign: TextAlign.center, // Align text to center
                            style: TextStyle(
                              fontSize: 14.0, // Adjust the font size
                              color: condition == value
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            condition == value
                                ? Color.fromARGB(255, 188, 225, 255)
                                : Colors.white,
                          ),
                          padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(
                                vertical: 8.0), // Adjust the vertical padding
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                color: condition == value
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Price',
            hintText: 'Enter the price of your listing',
            labelStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: TextStyle(
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(color: Colors.black),
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
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Contact Description',
            hintText: 'Enter contact information for your listing',
            labelStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: TextStyle(
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(color: Colors.black),
          onChanged: (value) {
            setState(() {
              ContactDescription = value;
            });
          },
          validator: (value) {
            return null;
          },
        ),
        SizedBox(height: 16),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: category,
            decoration: InputDecoration.collapsed(hintText: ''),
            onChanged: (String? newValue) {
              setState(() {
                category = newValue!;
              });
            },
            items: categories.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please choose a category';
              }
              return null;
            },
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Colors.black),
            itemHeight: 48,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              int listingId = await _submitListingDetails();
              if (listingId != -1) {
                print('Listing ID: $listingId');
                _submitListingPhoto(listingId);
              } else {
                print('Failed to submit listing details');
              }
            },
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              onPrimary: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
