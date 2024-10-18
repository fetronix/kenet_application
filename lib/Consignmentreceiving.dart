import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_pref_helper.dart'; // Adjust the import based on your file structure

class ConsignmentReceiving extends StatefulWidget {
  const ConsignmentReceiving({Key? key, required String title}) : super(key: key);

  @override
  State<ConsignmentReceiving> createState() => _ConsignmentReceivingState();
}

class _ConsignmentReceivingState extends State<ConsignmentReceiving> {
  final String apiUrl = 'http://197.136.16.164:8000/app/deliveries';
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _projectController = TextEditingController();
  final _commentsController = TextEditingController();
  String _assetDescription = '';
  String? _invoiceFilePath;
  String _personReceiving = ''; // Field for person receiving the asset (will get logged-in user)
  String? _userId; // Store the user ID

  @override
  void initState() {
    super.initState();
    _getLoggedInUser(); // Fetch the logged-in user on initialization
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Delivery')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _supplierNameController,
                decoration: InputDecoration(labelText: 'Supplier Name'),
                validator: (value) => value!.isEmpty ? 'Please enter supplier name' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter quantity' : null,
              ),
              // Removed the person receiving input field since it will use the logged-in user
              TextFormField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(labelText: 'Invoice Number'),
                validator: (value) => value!.isEmpty ? 'Please enter invoice number' : null,
              ),
              TextFormField(
                controller: _projectController,
                decoration: InputDecoration(labelText: 'Project'),
                validator: (value) => value!.isEmpty ? 'Please enter project' : null,
              ),
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(labelText: 'Comments'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile, // Pick the file when this button is clicked
                child: Text(_invoiceFilePath == null ? 'Select Invoice File' : 'Invoice Selected'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAsset, // Save and show the dialog on click
                child: const Text('Save Delivery'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show confirmation dialog with all input details
  void _showConfirmationDialog(Map<String, dynamic> asset) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Asset Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Supplier Name: ${asset['supplier_name']}'),
              Text('Quantity: ${asset['quantity']}'),
              Text('Invoice Number: ${asset['invoice_number']}'),
              Text('Project: ${asset['project']}'),
              Text('Comments: ${asset['comments']}'),
              Text('Person Receiving: $_userId'),
              Text('Invoice File: ${_invoiceFilePath != null ? "Selected" : "Not Selected"}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _saveAssetToServer(asset); // Save asset to server after confirmation
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Save Asset to Server
  void _saveAsset() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> asset = {
        'supplier_name': _supplierNameController.text,
        'quantity': _quantityController.text,
        'invoice_number': _invoiceNumberController.text,
        'project': _projectController.text,
        'comments': _commentsController.text,
        'person_receiving': _personReceiving,
      };
      _showConfirmationDialog(asset);
    }
  }

  // Method to send asset to server
  Future<void> _saveAssetToServer(Map<String, dynamic> asset) async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? accessToken = await sharedPrefHelper.getAccessToken(); // Retrieve access token

    try {
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
        throw Exception('Failed to add asset: ${response.body}');
      }
    } catch (error) {
      // Log any errors that occur during the save process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
