// ignore_for_file: file_names

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unm_marketplace/DioSingleton.dart';
import 'package:unm_marketplace/utils.dart';

class EditListingPage extends StatefulWidget {
  final int listingId;
  final Function() onSubmitted;

  EditListingPage({required this.listingId, required this.onSubmitted});

  @override
  _EditListingPageState createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController price = TextEditingController();
  TextEditingController contactDescription = TextEditingController();
  TextEditingController category = TextEditingController();
  TextEditingController condition = TextEditingController();
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
    print('Listing ID: ${widget.listingId}');
    _fetchListingDetails(widget.listingId);
    _initializeCondition(); // Initialize condition
    print('Categories : $categories');
  }

  Future<void> _fetchCategories() async {
    try {
      var response = await dio.post('http://${getHost()}/api/getCategories');

      if (response.statusCode == 200) {
        setState(() {
          categories = List<String>.from(response.data['categories']);
          category.text = categories.isNotEmpty ? categories[0] : '';
        });
      } else {
        print('Failed to fetch categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchListingDetails(int listingId) async {
    try {
      var response = await dio.post(
        'http://${getHost()}/api/RetrieveListing',
        queryParameters: {'id': listingId},
      );

      print(response.data);

      if (response.statusCode == 200) {
        if (response.data['listings'] != null &&
            response.data['listings'].isNotEmpty) {
          var listing = response.data['listings'][0];
          setState(() {
            title.text = listing['title'];
            description.text = listing['description'];
            price.text = listing['price'].toString();
            contactDescription.text = listing['ContactDescription'];
            category.text = listing['category'];
            condition.text = listing['condition'];
          });

          var imageDataResponse = await dio.get(
            'http://${getHost()}/images/Listing/${listing['ImageID']}',
            options: Options(responseType: ResponseType.bytes),
          );

          if (imageDataResponse.statusCode == 200) {
            setState(() {
              _imageBytes = Uint8List.fromList(imageDataResponse.data);
            });
          } else {
            print('Failed to fetch image data');
          }
        } else {
          print('No listing found');
        }
      } else {
        print('Failed to fetch listing details');
      }
    } catch (e) {
      print('Error fetching listing details: $e');
    }
  }

  void _initializeCondition() {
    condition.text = conditions.isNotEmpty ? conditions[0] : '';
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

  Future<void> _submitListingPhoto(int listingId) async {
    if (_imageBytes != null) {
      try {
        FormData formData = FormData.fromMap({
          'listingPhoto':
              MultipartFile.fromBytes(_imageBytes!, filename: 'image.jpg'),
          'id': listingId,
        });

        var response = await dio.post(
          'http://${getHost()}/api/UploadListingPhoto',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing photo uploaded successfully')),
          );
          Navigator.pop(context);
        } else {
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

  Future<void> _deleteOldPhoto(int listingId) async {
    try {
      final response = await dio.post(
        'http://${getHost()}/api/DeleteListingPhoto',
        data: {'id': listingId},
      );

      if (response.statusCode == 200) {
        print('Old photo deleted successfully');
      } else {
        print('Failed to delete old photo');
      }
    } catch (e) {
      print('Error deleting old photo: $e');
    }
  }

  Future<void> _submitEditedListing() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_imageBytes != null) {
          await _deleteOldPhoto(widget.listingId);
          await _submitListingPhoto(widget.listingId);
        }

        final response = await dio.post(
          'http://${getHost()}/api/EditListing',
          data: {
            'id': widget.listingId,
            'title': title.text,
            'description': description.text,
            'price': double.parse(price.text),
            'ContactDescription': contactDescription.text,
            'category': category.text,
            'condition': condition.text,
            'PostedBy': await _getUsername(),
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Listing details updated successfully')));
          widget.onSubmitted();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to update listing details')));
        }
      } catch (e) {
        print('Error submitting edited listing: $e');
      }
    }
  }

  Future<String> _getUsername() async {
    try {
      final response = await dio.post('http://${getHost()}/api/getUsername');
      return response.data['username'];
    } catch (e) {
      print('Error getting username: $e');
      return '';
    }
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
          controller: title, // Set the controller
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          onChanged: (value) {
            // Handle onChanged if needed
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
            controller: description, // Set the controller
            onChanged: (value) {
              // Handle onChanged if needed
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
                            condition.text =
                                value; // Update condition with selected value
                          });
                        },
                        child: Center(
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: condition.text == value
                                  ? Colors.blue
                                  : Colors
                                      .black, // Check against condition.text
                            ),
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            condition.text == value
                                ? Color.fromARGB(255, 188, 225, 255)
                                : Colors.white,
                          ),
                          padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 8.0),
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                color: condition.text == value
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
          controller: price, // Assign the controller
          onChanged: (value) {
            setState(() {
              price = value as TextEditingController;
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
          controller: contactDescription, // Assign the controller
          onChanged: (value) {
            setState(() {
              contactDescription = value as TextEditingController;
            });
          },
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please enter a contact description';
            }
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
            value: category
                .text, // Set the value to the text value of the TextEditingController
            decoration: InputDecoration.collapsed(hintText: ''),
            onChanged: (String? newValue) {
              setState(() {
                category.text = newValue ??
                    ''; // Update the text value of the TextEditingController
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
            onPressed: () {
              _submitEditedListing();
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
}
