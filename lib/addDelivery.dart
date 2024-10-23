import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import for MediaType
import 'package:image_picker/image_picker.dart';
import 'shared_pref_helper.dart';

class DeliveryReceiving extends StatefulWidget {
  const DeliveryReceiving({Key? key, required String title}) : super(key: key);

  @override
  State<DeliveryReceiving> createState() => _DeliveryReceivingState();
}

class _DeliveryReceivingState extends State<DeliveryReceiving> {
  String _supplierNameController = '';
  String _quantityController = '';
  String _invoiceNumberController = '';
  String _projectController = '';
  String _commentsController = '';
  String _personReceiving = ''; // For person receiving the asset
  String? _userId;

  File? _selectedFile;
  String _fileType = ''; // To indicate whether it's an image or a document

  final String apiUrl = 'http://197.136.16.164:8000/app/delivery/new/';
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
  }

  Future<void> _getLoggedInUser() async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? userId = await sharedPrefHelper.getUserId(); // Get the logged-in user ID
    setState(() {
      _personReceiving = userId ?? '';
      _userId = userId;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _selectedFile = File(pickedImage.path);
        _fileType = 'image';
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'], // Allow only certain file types
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'document';
      });
    }
  }

  Future<void> _saveAsset(Map<String, dynamic> asset, File? file) async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? accessToken = await sharedPrefHelper.getAccessToken(); // Retrieve access token

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $accessToken';

    // Convert all fields to string for request
    request.fields.addAll({
      'date_delivered': asset['date_delivered'].toString(),
      'person_receiving': asset['person_receiving'].toString(),
      'supplier_name': asset['supplier_name'].toString(),
      'quantity': asset['quantity'].toString(),
      'invoice_number': asset['invoice_number'].toString(),
      'project': asset['project'].toString(),
      'comments': asset['comments'].toString(),
    });

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'invoice_file',
        file.path,
        contentType: _fileType == 'image'
            ? MediaType('image', 'jpeg')
            : MediaType('application', 'pdf'),
      ));
    }

    var response = await request.send();
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add asset. Error code: ${response.statusCode}')),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? personReceivingId = await sharedPrefHelper.getUserId(); // Get user ID

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm  Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Person Receiving: $personReceivingId'),
              Text('Supplier Name: $_supplierNameController'),
              Text('Quantity: $_quantityController'),
              Text('Invoice Number: $_invoiceNumberController'),
              Text('Project: $_projectController'),
              Text('Comments: $_commentsController'),
              Text('File: ${_selectedFile?.path ?? "No file selected"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final asset = {
                  'date_delivered': DateTime.now().toIso8601String(),
                  'person_receiving': personReceivingId,
                  'supplier_name': _supplierNameController,
                  'quantity': _quantityController,
                  'invoice_number': _invoiceNumberController,
                  'project': _projectController,
                  'comments': _commentsController,
                };
                _saveAsset(asset, _selectedFile);
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Receiving'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 400,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _supplierNameController = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Supplier Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _quantityController = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _invoiceNumberController = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Invoice Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _projectController = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Project',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _commentsController = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Comments',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera),
                                label: const Text('Take Picture'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Select Invoice File'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showConfirmationDialog,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text('Submit'),
                          ),
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
