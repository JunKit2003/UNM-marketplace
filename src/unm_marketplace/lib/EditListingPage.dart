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
  TextEditingController ContactDescription = TextEditingController();
  TextEditingController category = TextEditingController();
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
    print('Listing ID: ${widget.listingId}');
    // Fetch listing details
    category.text = categories.isNotEmpty ? categories[0] : '';
    _fetchListingDetails(widget.listingId);
  }

  Future<void> _fetchListingDetails(int listingId) async {
    try {
      // Fetch listing details using the provided listingId
      var response = await dio.post(
        'http://${getHost()}:5000/api/RetrieveListing',
        queryParameters: {'id': listingId},
      );

      print(response.data);

      if (response.statusCode == 200) {
        // Check if listings array is not empty
        if (response.data['listings'] != null &&
            response.data['listings'].isNotEmpty) {
          // Access the first listing in the array
          var listing = response.data['listings'][0];
          // Update state with fetched listing details
          setState(() {
            title.text = listing['title'];
            description.text = listing['description'];
            price.text = listing['price'].toString();
            ContactDescription.text = listing['ContactDescription'];
            category.text = listing['category'];
          });

          // Fetch image data using ImageID
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
          // Handle empty or null listings array
          print('No listing found');
        }
      } else {
        // Handle error response
        print('Failed to fetch listing details');
      }
    } catch (e) {
      print('Error fetching listing details: $e');
    }
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

  Future<void> _deleteOldPhoto(int listingId) async {
    try {
      // Send a request to delete the old photo using the listing ID
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
        // Check if there's a new image to upload
        if (_imageBytes != null) {
          // Delete the old photo from the server before uploading the new one
          await _deleteOldPhoto(widget.listingId);
          // Upload the new photo
          await _submitListingPhoto(widget.listingId);
        }

        // Send edited listing details
        final response = await dio.post(
          'http://${getHost()}:5000/api/EditListing',
          data: {
            'id': widget.listingId,
            'title': title.text,
            'description': description.text,
            'price': double.parse(price.text),
            'ContactDescription': ContactDescription.text,
            'category': category.text,
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Listing details updated successfully')));
            // Call the callback function to refresh the ListedAd page
            widget.onSubmitted();
            // Navigate back to the previous screen (ListedAd page)
            Navigator.pop(context);
          }
        } else {
          // Error response
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Failed to update listing details')));
          }
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
                controller: ContactDescription,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description on how the buyer will contact you';
                  }
                  return null;
                },
              ),
              // DropdownButtonFormField for category selection
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
