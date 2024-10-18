import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_pref_helper.dart'; // Adjust the import based on your file structure

class DeliveryReceiving extends StatefulWidget {
  const DeliveryReceiving({Key? key, required String title}) : super(key: key);

  @override
  State<DeliveryReceiving> createState() => _DeliveryReceivingState();
}

class _DeliveryReceivingState extends State<DeliveryReceiving> {
  final List<Map<String, dynamic>> _scannedAssets = [];
  String _assetDescription = '';
  String _supplierNameController = '';
  String _quantityController = '';
  String _invoiceNumberController = '';
  String _projectController = '';
  String _commentsController ='' ;
  String? _invoiceFilePath;
  String _personReceiving = ''; // Field for person receiving the asset (will get logged-in user)
  String? _userId;


  final String apiUrl = 'http://197.136.16.164:8000/app/deliveries/';


  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
  }

  // Method to get the current logged-in user ID
  Future<void> _getLoggedInUser() async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? userId = await sharedPrefHelper.getUserId(); // Assuming getUserId() gets the logged-in user ID
    setState(() {
      _personReceiving = userId ?? ''; // Set the person receiving to the logged-in user
      _userId = userId; // Store userId for display in the dialog
    });
  }
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDF files
    );

    if (result != null) {
      setState(() {
        _invoiceFilePath = result.files.single.path;
      });
    }
  }



  Future<void> _saveAsset(Map<String, dynamic> asset) async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? accessToken = await sharedPrefHelper.getAccessToken(); // Retrieve access token

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Add authorization header
      },
      body: jsonEncode(asset),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add asset: ${response.body}')),
      );
    }
  }



  Future<bool> _showConfirmationDialog() async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? personReceivingId = await sharedPrefHelper.getUserId(); // Assuming you have a method to get user ID

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm  Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Person Receiving: $personReceivingId'),
              Text('Asset Description: $_assetDescription'),
              Text('Supplier Name: $_supplierNameController'),
              Text('Quantity: $_quantityController'),
              Text('Invoice Number: $_invoiceNumberController'),
              Text('Project: $_projectController'),
              Text('Comments: $_commentsController'),
              Text('Person Receiving: $_userId'),
              Text('Invoice File: $_invoiceFilePath'),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final asset = {
                  'date_received': DateTime.now().toIso8601String(),
                  'person_receiving': personReceivingId, // Set to current user ID
                  'asset_description': _assetDescription,
                };
                _saveAsset(asset);
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Receiving'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 400, // Set the width of the form here
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
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
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
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
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
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
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
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
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
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _pickFile, // Pick the file when this button is clicked
                            child: Text(_invoiceFilePath == null ? 'Select Invoice File' : 'Invoice Selected'),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: _showConfirmationDialog,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF653D82)), // Set the outline color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0), // Increased value for more rounded edges
                              ),
                            ),
                            child: const Text(
                              'Save Asset',
                              style: TextStyle(
                                color: Color(0xFF653D82), // Set the text color to match the outline
                                fontWeight: FontWeight.bold, // Set the font weight to bold
                                fontSize: 18, // Set the font size to 18
                              ),
                            ),
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
