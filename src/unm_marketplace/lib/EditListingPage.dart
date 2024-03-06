import 'dart:typed_data';
import 'package:dio/dio.dart';
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
      var response =
          await dio.post('http://${getHost()}:5000/api/getCategories');

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
        'http://${getHost()}:5000/api/RetrieveListing',
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
            'http://${getHost()}:5000/images/${listing['ImageID']}',
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
          'http://${getHost()}:5000/api/UploadListingPhoto',
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
        'http://${getHost()}:5000/api/DeleteListingPhoto',
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
          'http://${getHost()}:5000/api/EditListing',
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
      final response =
          await dio.post('http://${getHost()}:5000/api/getUsername');
      return response.data['username'];
    } catch (e) {
      print('Error getting username: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                controller: title,
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
                controller: description,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Condition'),
                value: condition.text,
                onChanged: (String? newValue) {
                  setState(() {
                    condition.text = newValue!;
                  });
                },
                items: conditions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a condition';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                controller: price,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contact Description'),
                controller: contactDescription,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description on how the buyer will contact you';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category'),
                value: category.text,
                onChanged: (String? newValue) {
                  setState(() {
                    category.text = newValue!;
                  });
                },
                items: categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a category';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  _submitEditedListing();
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
