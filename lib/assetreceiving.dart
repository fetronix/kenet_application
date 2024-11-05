import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:kenet_application/addDelivery.dart';
import 'shared_pref_helper.dart'; // Adjust the import based on your file structure

class AssetReceiving extends StatefulWidget {
  const AssetReceiving({Key? key, required String title}) : super(key: key);

  @override
  State<AssetReceiving> createState() => _AssetReceivingState();
}

class _AssetReceivingState extends State<AssetReceiving> {
  final List<Map<String, dynamic>> _scannedAssets = [];
  String _assetDescription = '';
  String _assetDescriptionModel = '';
  String? _selectedStatus;
  Map<String, dynamic>? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];

  Map<String, dynamic>? _location;
  List<Map<String, dynamic>> _locations = [];

  Map<String, dynamic>? _selectedDelivery;
  List<Map<String, dynamic>> _deliveries = [];

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

  final String deliveryApiUrl =
      'http://197.136.16.164:8000/app/api/mydeliveries/';
  final String locationApiUrl =
      'http://197.136.16.164:8000/app/api/locations/';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchDeliveries();
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


// Method to fetch deliveries
  Future<void> _fetchDeliveries() async {
    final response = await http.get(Uri.parse(deliveryApiUrl));
    if (response.statusCode == 200) {
      List<dynamic> deliveryList = jsonDecode(response.body);
      setState(() {
        _deliveries = deliveryList.map((delivery) => {
          'id': delivery['id'],
          'details': '${delivery['supplier_name'] ?? "Unknown Supplier"} - Quantity: ${delivery['quantity'] ?? 0} - Invoice: ${delivery['invoice_number'] ?? "No Invoice"}',
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load deliveries: ${response.body}')),
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

  void _physicalScan() {

    // Step 1: Ask the user for the number of items to scan
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int itemCount = 1; // Default to 1 item
        return AlertDialog(
          title: Text("Number of Items to Scan"),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter number of items"),
            onChanged: (value) {
              itemCount = int.tryParse(value) ?? 1; // Parse to int, default to 1 if invalid
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, itemCount); // Pass the item count back
              },
              child: Text("Next"),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Step 2: Start the scanning process
        _scanItems(value);
      }
    });
  }

  void _scanItems(int itemCount) {
    final List<Map<String, String>> scannedItems = [];

    // Assuming _assetDescription is already set from the input form
    String assetDescription = _assetDescription; // Get from the form, no additional input needed
    String assetDescriptionModel = _assetDescriptionModel; // Get from the form, no additional input needed

    Future<void> _scanItem(int index) async {
      String? serialNumber = await _scanInput("Enter Serial Number for Item ${index + 1}");
      if (serialNumber == null) {
        _showSummary(scannedItems); // Show summary if canceled
        return; // Exit the scanning loop
      }

      String? kenetTagNumber = await _scanInput("Enter KENET Tag Number for Item ${index + 1}");
      if (kenetTagNumber == null) {
        _showSummary(scannedItems); // Show summary if canceled
        return; // Exit the scanning loop
      }

      // Retrieve the person receiving ID from shared preferences
      SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
      String? personReceivingId = await sharedPrefHelper.getUserId();

      String selectedCategory = _selectedCategory != null ? _selectedCategory!['name'] : "Not Selected";
      // Example usage of selected delivery
      String selectedDelivery = _selectedDelivery != null
          ? _selectedDelivery!['details'] as String? ?? "Details not available"
          : "Not Selected";
      String selectedStatus = _selectedStatus ?? "Not Selected";
      String location = _location != null ? _location!['name'] : "Not Selected";
      String date = DateTime.now().toIso8601String();

      scannedItems.add({
        "serial": serialNumber,
        "kenetTag": kenetTagNumber,
        "personReceiving": personReceivingId ?? "Not Found", // Handle case if user ID is not found
        "assetDescription": assetDescription,
        "assetDescriptionModel": assetDescriptionModel,
        "category": selectedCategory,
        "delivery": selectedDelivery,
        "status": selectedStatus,
        "location": location,
        "date": date,
      });

      if (index + 1 < itemCount) {
        _scanItem(index + 1); // Scan next item
      } else {
        _showSummary(scannedItems);
      }
    }

    _scanItem(0);
  }

  Future<String?> _scanInput(String title) async {
    String? inputValue; // Change to nullable String
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    // Display a dialog to capture the input
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode, // Set the focus node to the text field
            autofocus: true, // Focus on this input field
            decoration: InputDecoration(hintText: "Enter value"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                inputValue = controller.text; // Get the input value
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Submit"),
            ),
            TextButton(
              onPressed: () {
                controller.clear(); // Clear the text field
                focusNode.requestFocus(); // Set focus back to the text field
              },
              child: Text("Clear"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, null); // Return null to indicate cancellation
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );

    return inputValue; // Return the captured value or null
  }




  void _showSummary(List<Map<String, String>> scannedItems) {
    List<Widget> summaryItems = [];
    Set<String> uniqueIdentifiers = Set(); // To track unique identifiers
    List<Map<String, String>> uniqueItems = []; // For storing unique items
    List<Map<String, String>> duplicateItems = []; // For storing duplicate items

    // Build the summary details for each scanned item
    for (var item in scannedItems) {
      // Create a unique identifier for each item (combining serial and kenet tag)
      String identifier = "${item['serial']}-${item['kenetTag']}";

      if (!uniqueIdentifiers.contains(identifier)) {
        uniqueIdentifiers.add(identifier);
        uniqueItems.add(item); // Save unique item
      } else {
        duplicateItems.add(item); // Save duplicate item
      }

      summaryItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0), // Add some spacing between items
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Serial: ${item['serial']}"),
              Text("KENET Tag: ${item['kenetTag']}"),
              Text("Person Receiving: ${item['personReceiving']}"),
              Text("Asset Description: ${item['assetDescription']}"),
              Text("Asset Description Model: ${item['assetDescriptionModel']}"),
              Text("Category: ${item['category']}"),
              Text("Delivery: ${item['delivery']}"),
              Text("Status: ${item['status']}"),
              Text("Location: ${item['location']}"),
              Text("Date: ${item['date']}"),
              Divider(), // Optional divider between items for clarity
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Scanned Items Summary"),
          content: Container(
            width: double.maxFinite, // Make the dialog width responsive
            child: SingleChildScrollView(
              child: Column(
                children: summaryItems,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Loop through unique items and save each to the database
                for (var item in uniqueItems) {
                  final asset = {
                    'date_received': DateTime.now().toIso8601String(),
                    'person_receiving': item['personReceiving'], // Current user ID
                    'asset_description': item['assetDescription'],
                    'asset_description_model': item['assetDescriptionModel'],
                    'serial_number': item['serial'],
                    'kenet_tag': item['kenetTag'],
                    'location': _location?['id'],
                    'category': _selectedCategory?['id'],
                    'delivery': _selectedDelivery?['id'],
                    'status': _selectedStatus,
                  };

                  // Call the method to save the asset
                  await _saveAsset(asset);
                }

                // Show a SnackBar if there were duplicates
                if (duplicateItems.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Duplicates found! Only one instance of identical items has been saved."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                // Close the dialog after saving
                Navigator.of(context).pop(true);
              },
              child: const Text('Save All Assets'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }






  Future<void> _scanItem() async {
    if (_assetDescription.isEmpty ||
        _assetDescriptionModel.isEmpty ||
        _selectedCategory == null ||
        _selectedDelivery == null ||
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
  void _navigateToDeliveryReceiving() {
    Navigator.push(
      context, // Use the current context
      MaterialPageRoute(
        builder: (context) => DeliveryReceiving(title: 'fd'), // No need to cast
      ),
    );
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
              Text('Asset Description Model: $_assetDescriptionModel'),
              Text('Category: ${_selectedCategory != null ? _selectedCategory!['name'] : "Not Selected"}'),
              Text('Delivery: ${_selectedDelivery != null ? _selectedDelivery!['delivery_id'] : "Not Selected"}'),
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
                  'asset_description_model': _assetDescriptionModel,
                  'serial_number': serialNumber,
                  'kenet_tag': kenetTag,
                  'location': _location?['id'],
                  'category': _selectedCategory?['id'],
                  'delivery': _selectedDelivery?['id'],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the buttons horizontally
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: OutlinedButton.icon(
                          onPressed: _navigateToDeliveryReceiving,
                          icon: Icon(Icons.add, color: Color(0xFF653D82)),
                          label: Text('Register New Consignment', style: TextStyle(color: Color(0xFF653D82))),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Color(0xFF653D82), width: 2),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _assetDescription = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Asset Description Model',
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
                              hint: const Text('Select Consignment to Asset'),
                              value: _selectedDelivery,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDelivery = value;
                                });
                              },
                              items: _deliveries.map((delivery) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: delivery,
                                  child: Text(delivery['details'] ?? "No Details Available"), // Change here
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
                          // Buttons for scanning
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _physicalScan, // Method to handle physical barcode scan
                                icon: Icon(Icons.qr_code_scanner),
                                label: const Text("Physical Scanner"),
                              ),
                              ElevatedButton.icon(
                                onPressed: _scanItem, // Method to handle camera scan
                                icon: Icon(Icons.camera_alt),
                                label: const Text("Camera Scan"),
                              ),
                            ],
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

