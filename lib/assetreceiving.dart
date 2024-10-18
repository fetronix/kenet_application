import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'shared_pref_helper.dart'; // Adjust the import based on your file structure

class AssetReceiving extends StatefulWidget {
  const AssetReceiving({Key? key, required String title}) : super(key: key);

  @override
  State<AssetReceiving> createState() => _AssetReceivingState();
}

class _AssetReceivingState extends State<AssetReceiving> {
  final List<Map<String, dynamic>> _scannedAssets = [];
  String _assetDescription = '';
  String? _selectedStatus;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _location;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];
  List<String> _statuses = [
    'instore',
    'tested',
    'default',
    'onsite',
    'pending_release'
  ];
  List<Map<String, dynamic>> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();
  String _serialPrefix = '';

  final String apiUrl = 'http://197.136.16.164:8000/app/assets/';
  final String categoryApiUrl =
      'http://197.136.16.164:8000/app/api/categories/';
  final String locationApiUrl =
      'http://197.136.16.164:8000/app/api/locations/';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchLocations();
    _filteredLocations = _locations;
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse(categoryApiUrl));
    if (response.statusCode == 200) {
      List<dynamic> categoryList = jsonDecode(response.body);
      setState(() {
        _categories = categoryList.map((category) => {
          'id': category['id'],
          'name': category['name'],
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: ${response.body}')),
      );
    }
  }

  Future<void> _fetchLocations() async {
    final response = await http.get(Uri.parse(locationApiUrl));
    if (response.statusCode == 200) {
      List<dynamic> locationList = jsonDecode(response.body);
      setState(() {
        _locations = locationList.map((location) => {
          'id': location['id'],
          'name': location['name'],
        }).toList();
        _filteredLocations = _locations;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load locations: ${response.body}')),
      );
    }
  }

  void _filterLocations(String query) {
    final filtered = _locations.where((location) {
      return location['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredLocations = filtered;
    });
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

  Future<void> _scanItem() async {
    if (_assetDescription.isEmpty ||
        _selectedCategory == null ||
        _selectedStatus == null ||
        _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final itemCount = await _showItemCountDialog();
    if (itemCount == null || itemCount <= 0) return;

    _serialPrefix = await _showSerialPrefixDialog();
    if (_serialPrefix.isEmpty) return;

    for (int i = 0; i < itemCount; i++) {
      while (true) {
        var resultSerial = await BarcodeScanner.scan();
        if (resultSerial.type == ResultType.Cancelled) {
          break;
        }
        if (resultSerial.rawContent.isNotEmpty &&
            resultSerial.rawContent.startsWith(_serialPrefix)) {
          while (true) {
            var resultKenet = await BarcodeScanner.scan();
            if (resultKenet.type == ResultType.Cancelled) {
              break;
            }
            if (resultKenet.rawContent.isNotEmpty &&
                resultKenet.rawContent.startsWith('K')) {
              bool isConfirmed = await _showConfirmationDialog(
                resultSerial.rawContent,
                resultKenet.rawContent,
              );
              if (isConfirmed) break;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'KENET Tag must start with "K". Please scan again.')),
              );
              await Future.delayed(const Duration(seconds: 3));
            }
          }
          break;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Serial number must start with "$_serialPrefix". Please scan again.'),
            ),
          );
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
  }

  Future<int?> _showItemCountDialog() {
    TextEditingController controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('How many items are you scanning?'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter number of items'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(int.tryParse(controller.text));
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _showSerialPrefixDialog() async {
    TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Serial Number Prefix'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                hintText:
                'Prefix is the first 3 Numbers of the serial barcode'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    return result ?? '';
  }

  Future<bool> _showConfirmationDialog(
      String serialNumber, String kenetTag) async {
    SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
    String? personReceivingId = await sharedPrefHelper.getUserId(); // Assuming you have a method to get user ID

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Scan Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Serial Number: $serialNumber'),
              Text('KENET Tag: $kenetTag'),
              Text('Person Receiving: $personReceivingId'),
              Text('Asset Description: $_assetDescription'),
              Text('Category: ${_selectedCategory != null ? _selectedCategory!['name'] : "Not Selected"}'),
              Text('Status: ${_selectedStatus ?? "Not Selected"}'),
              Text('Location: ${_location != null ? _location!['name'] : "Not Selected"}'),
              Text('Date: ${DateTime.now().toIso8601String()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final asset = {
                  'date_received': DateTime.now().toIso8601String(),
                  'person_receiving': personReceivingId, // Set to current user ID
                  'asset_description': _assetDescription,
                  'serial_number': serialNumber,
                  'kenet_tag': kenetTag,
                  'location': _location?['id'],
                  'category': _selectedCategory?['id'],
                  'status': _selectedStatus,
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
                                _assetDescription = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Asset Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Rounded border
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0), // Adjust the radius as needed
                              border: Border.all(color: Colors.grey), // Set border color and width
                            ),
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                              hint: const Text('Select Category'),
                              value: _selectedCategory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category['name']),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                border: InputBorder.none, // Remove default border
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Add padding if needed
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
                              hint: const Text('Select Status'),
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
                          TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Location',
                              prefixIcon: Icon(Icons.search), // Adding search icon inside the search bar
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Making the border rounded
                              ),
                            ),
                            onChanged: (query) {
                              _filterLocations(query);
                            },
                          ),

                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0), // Adjust the radius as needed
                              border: Border.all(color: Colors.grey), // Set border color and width
                            ),
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                              hint: const Text('Select Location'),
                              value: _location,
                              onChanged: (value) {
                                setState(() {
                                  _location = value;
                                });
                              },
                              items: _filteredLocations.map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Text(location['name']),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                border: InputBorder.none, // Remove default border
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Add padding if needed
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _scanItem,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF653D82)), // Set the outline color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0), // Increased value for more rounded edges
                              ),
                            ),
                            child: const Text(
                              'Scan Asset',
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
