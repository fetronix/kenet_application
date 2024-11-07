import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

class AdminScreen extends StatefulWidget {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String accessToken;
  final String refreshToken;

  const AdminScreen({
    Key? key,
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  }) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> checkoutItems = [];
  bool isLoading = true;
  String userDetails = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCheckoutItems();
    _loadUserDetails();
  }

  Future<void> _fetchCheckoutItems() async {
    final url = 'http://197.136.16.164:8000/app/checkoutsadmin/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {

        final List<dynamic> jsonResponse = jsonDecode(response.body);

        setState(() {
          checkoutItems = jsonResponse.map((item) {
            return {
              'checkout_id': item['id'],
              'username': item['cart_items'][0]['user'], // Ensure cart_items array exists
              'checkout_date': item['checkout_date'] != null
                  ? DateTime.parse(item['checkout_date'])
                  : DateTime.now(),
              'remarks': item['remarks'] ?? 'No Remarks',
              'cart_items': item['cart_items'] is List ? item['cart_items'] : [],
            };
          }).toList();
        });
      } else {
        _showSnackbar('Failed to fetch checkout items: ${response.body}'); // Show error response body for debugging
      }
    } catch (e) {

      _showSnackbar('Error fetching checkout items: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userDetails = prefs.getString('userDetails') ?? 'No user details found';
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userDetails'); // Clear stored user details
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login page
  }

  Future<void> _approveCheckout(int checkoutId) async {
    final url = 'http://197.136.16.164:8000/app/checkout/$checkoutId/approve/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSnackbar('Checkout approved successfully.');
        _fetchCheckoutItems(); // Refresh the list after approval
      } else {
        _showSnackbar('Failed to approve checkout: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Error approving checkout: $e');
    }
  }

  void _showApprovalDialog(int checkoutId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Approve Users Dispatch'),
          content: Text('Do you want to approve this checkout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _approveCheckout(checkoutId); // Call the approval function
              },
              child: Text('Approve'),
            ),
          ],
        );
      },
    );
  }




  void _showCheckoutDialog(int checkoutId) async {
    final TextEditingController remarksController = TextEditingController();
    final TextEditingController quantityRequiredController = TextEditingController();
    final TextEditingController quantityIssuedController = TextEditingController();
    final TextEditingController authorizingNameController = TextEditingController();
    final SignatureController signatureController = SignatureController(penColor: Colors.black);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update The Approved Checkout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: remarksController,
                  decoration: InputDecoration(labelText: 'Remarks'),
                  maxLines: 3,
                ),
                TextField(
                  controller: quantityRequiredController,
                  decoration: InputDecoration(labelText: 'Quantity Required'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityIssuedController,
                  decoration: InputDecoration(labelText: 'Quantity Issued'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: authorizingNameController,
                  decoration: InputDecoration(labelText: 'Authorizing Name'),
                ),
                SizedBox(height: 20),
                Text('Signature'),
                Container(
                  height: 100,
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    signatureController.clear();
                  },
                  child: Text('Clear Signature'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Convert the signature to base64 if provided
                String? signatureBase64;
                try {
                  if (signatureController.isNotEmpty) {
                    final signatureImage = await signatureController.toImage();
                    final pngBytes = await signatureImage!.toByteData(format: ui.ImageByteFormat.png);
                    signatureBase64 = base64Encode(pngBytes!.buffer.asUint8List());
                  }
                } catch (e) {
                  _showSnackbar("Error encoding signature: $e");
                }

                // Gather the input data
                final updatedData = {
                  'remarks': remarksController.text,
                  'quantity_required': int.tryParse(quantityRequiredController.text) ?? 1,
                  'quantity_issued': int.tryParse(quantityIssuedController.text) ?? 1,
                  'authorizing_name': authorizingNameController.text,
                  if (signatureBase64 != null) 'signature_image': signatureBase64,
                };

                // Send the updated data to your checkout update method here
                await _updateCheckout(checkoutId, updatedData);

                Navigator.of(context).pop(); // Close the dialog after confirmation
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updateCheckout(int checkoutId, Map<String, dynamic> updatedData) async {
    final url = 'http://197.136.16.164:8000/app/checkout/$checkoutId/update/'; // Update with your actual URL
    final token = widget.accessToken; // Replace with the user's actual auth token

    // Add authorization and necessary headers
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Make the HTTP PUT request to update the checkout
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {

      _showSnackbar("Checkout data updated successfully");
    } else {
      _showSnackbar("Error: ${response.body}");
    }
  }

  Map<String, dynamic> _extractAssetDetails(String asset) {
    final regex = RegExp(
        r'^(.*?)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)$');
    final match = regex.firstMatch(asset);

    if (match != null) {
      return {
        'name': match.group(1) ?? 'Unknown',
        'serial_number': match.group(2) ?? 'N/A',
        'kenet_tag': match.group(3) ?? 'N/A',
        'location_received': match.group(4) ?? 'N/A',
        'name_model': match.group(5) ?? 'N/A',
        'status': match.group(6) ?? 'N/A',
        'AssetId': int.tryParse(match.group(7) ?? '0') ?? 0,
        'new_location': match.group(8) ?? 'N/A',
      };
    }
    return {
      'name': 'Unknown',
      'serial_number': 'N/A',
      'kenet_tag': 'N/A',
      'location_received': 'N/A',
      'new_location': 'N/A',
      'status': 'N/A',
      'AssetId': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove the back button
          title: Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF9C27B0),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchCheckoutItems, // Pull-to-refresh function
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.firstName} ${widget.lastName}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Your Email: ${widget.email}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                // Search form
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _logout,
                      child: Text('Logout'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: checkoutItems.isNotEmpty
                      ? ListView.builder(
                    itemCount: checkoutItems.length,
                    itemBuilder: (context, index) {
                      final item = checkoutItems[index];
                      return GestureDetector(
                        onTap: () => _showApprovalDialog(item['checkout_id']),
                        child: Card(
                          margin: EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Dispatching: ${item['username']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Checkout Date: ${item['checkout_date']}'),
                                Divider(),
                                Text(
                                  'Cart Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (item['cart_items'].isNotEmpty)
                                  Table(
                                    border: TableBorder.all(),
                                    columnWidths: {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(1),
                                      3: FlexColumnWidth(1),
                                      4: FlexColumnWidth(1),
                                      5: FlexColumnWidth(1),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Asset Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Serial Number', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('KNET Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Received Location', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('New Location', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ...item['cart_items'].map<TableRow>((cartItem) {

                                        final assetDetails = _extractAssetDetails(cartItem['asset']);
                                        // Debugging asset details
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['name'] ?? 'N/A'),  // Default to 'N/A' if null
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['serial_number'] ?? 'N/A'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['kenet_tag'] ?? 'N/A'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['location_received'] ?? 'N/A'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['status'] ?? 'N/A'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(assetDetails['new_location'] ?? 'N/A'),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  )
                                else
                                  Text('No items in the cart.'),
                                // Conditional button rendering
                                ElevatedButton(
                                  onPressed: () {


                                    bool isApproved = item['cart_items'].any((cartItem) {
                                      final assetDetails = _extractAssetDetails(cartItem['asset']); // Parsing the asset string
                                      return assetDetails['status'] == 'approved';  // Check status
                                    });

                                    if (isApproved) {
                                      _showCheckoutDialog(item['checkout_id']);

                                    } else {
                                      // If not approved, approve the checkout
                                      _approveCheckout(item['checkout_id']);
                                    }
                                  },
                                  child: Text(
                                    item['cart_items'].any((cartItem) {
                                      final assetDetails = _extractAssetDetails(cartItem['asset']);
                                      return assetDetails['status'] == 'approved';
                                    })
                                        ? 'Release Asset'
                                        : 'Approve',
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )

                      : Center(child: Text('No checkout items available.')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
