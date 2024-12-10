import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import for MediaType
import 'package:image_picker/image_picker.dart';
import 'package:kenet_application/allUrls.dart';
import 'assetreceiving.dart';
import 'shared_pref_helper.dart';
import 'dart:convert';


class DeliveryReceiving extends StatefulWidget {
  const DeliveryReceiving({super.key, required String title});

  @override
  State<DeliveryReceiving> createState() => _DeliveryReceivingState();
}

class _DeliveryReceivingState extends State<DeliveryReceiving> {
  final String _supplierNameController = '';
  String _quantityController = '';
  String _invoiceNumberController = '';
  final String _projectController = '';
  String _commentsController = '';
  String _personReceiving = ''; // For person receiving the asset
  String? _userId;

  String? _selectedsupplierId; // For storing the selected supplier ID
  List<Map<String, dynamic>> _suppliers = [];
  final String supplierApiUrl =ApiUrls.supplierurl;

  File? _selectedFile;
  String _fileType = ''; // To indicate whether it's an image or a document

  final String apiUrl = ApiUrls.addconsignmenturl;
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedStatus;
  final List<String> _statuses = [
    'noc',
    'netdev',
    'bolt',
    'dci',
    'data_centre_infrastructure'
  ];

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    _fetchsuppliers();
  }

  Future<void> _getLoggedInUser() async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? userId = await sharedPrefHelper.getUserId(); // Get the logged-in user ID
    setState(() {
      _personReceiving = userId ?? '';
      _userId = userId;
    });
  }

  Future<void> _fetchsuppliers() async {
    try {
      final response = await http.get(Uri.parse(supplierApiUrl));
      if (response.statusCode == 200) {
        // Parse the response body
        final List<dynamic> suppliers = jsonDecode(response.body);
        setState(() {
          _suppliers = suppliers.map((supplier) {
            return {
              'id': supplier['id'].toString(),
              'name': supplier['name'], // Assuming 'name' is the supplier name field
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load suppliers');
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
    }
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
      'supplier_id': asset['supplier_id'].toString(),
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
        const SnackBar(content: Text('Consignment added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add Consignment. Error code: ${response.statusCode}')),
      );
    }
  }

  void _navigateToAssetReceiving() {
    Navigator.push(
      context, // Use the current context
      MaterialPageRoute(
        builder: (context) => AssetReceiving(title: 'fd'), // No need to cast
      ),
    );
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
              Text('Quantity: $_quantityController'),
              Text('Invoice Number: $_invoiceNumberController'),
              Text('Project: $_selectedStatus'),
              Text('Comments: $_commentsController'),
              Text('Supplier Name: ${_suppliers.firstWhere((supplier) => supplier['id'] == _selectedsupplierId)['name'] ?? "Not selected"}'),
              Text('File: ${_selectedFile?.path ?? "No file selected"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final asset = {
                  'date_delivered': DateTime.now().toIso8601String(),
                  'person_receiving': personReceivingId,
                  'quantity': _quantityController,
                  'invoice_number': _invoiceNumberController,
                  'project': _selectedStatus,
                  'comments': _commentsController,
                  'supplier_name': _selectedsupplierId,
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
            child: SizedBox(
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
                          DropdownButtonFormField<String>(
                            value: _selectedsupplierId,
                            hint: const Text('Select Supplier '),
                            items: _suppliers.map((supplier) {
                              return DropdownMenuItem<String>(
                                value: supplier['id'],
                                child: Text(supplier['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedsupplierId = value;
                              });
                            },
                            decoration: InputDecoration(
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0), // Adjust the radius as needed
                              border: Border.all(color: Colors.grey), // Set border color and width
                            ),
                            child: DropdownButtonFormField<String>(
                              hint: const Text('Select Project'),
                              value: _selectedStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                              items: _statuses.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                border: InputBorder.none, // Remove default border
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Add padding if needed
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


