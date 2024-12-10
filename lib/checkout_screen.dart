import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/allUrls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String accessToken;
  final String refreshToken;

  const CheckoutScreen({
    super.key,
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
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
    final url = ApiUrls.checkoutuserList;

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
            final cartItems = item['cart_items'] is List ? item['cart_items'] : [];
            return {
              'checkout_id': item['id'],
              'username': cartItems.isNotEmpty ? cartItems[0]['user'] : 'Unknown User',
              'checkout_date': item['checkout_date'] != null
                  ? DateTime.parse(item['checkout_date'])
                  : DateTime.now(),
              'remarks': item['remarks'] ?? 'No Remarks',
              'cart_items': cartItems,
              'image_user': item['user_signature_image'],
              'image_user_admin': item['signature_image'],

            };
          }).toList();
          print(checkoutItems);
        });
      } else {
        _showSnackbar('Failed to fetch checkout items: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Error fetching checkout items: $e');
      print('Error fetching checkout items: $e');
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


  // Method to open an external URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackbar('Could not launch $url');
    }
  }


  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userDetails'); // Clear stored user details
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login page
  }

  void _viewPdf(int checkoutId) {
    // Launch the URL with the provided checkoutId
    _launchURL(ApiUrls.getCheckoutDetail(checkoutId));
  }


  void _showCheckoutDialog(int checkoutId) async {
    final TextEditingController remarksController = TextEditingController();
    final SignatureController signatureController = SignatureController(penColor: Colors.blue);

    // Calculate the total count of items in the checkout cart
    final int totalItems = checkoutItems.fold<int>(0, (sum, item) {
      return sum + (item['cart_items'] as List).length;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update The Download PDF'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please Add your Signature to Download PDF'),
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
                  _showSnackbar("Error encoding your signature: $e");
                }

                // Gather the input data
                final updatedData = {
                  if (signatureBase64 != null) 'user_signature_image': signatureBase64,
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
    final url = ApiUrls.updateuserCheckoutDetail(checkoutId); // Update with your actual URL
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
            'Dispatch List Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF9C27B0),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchCheckoutItems, // Pull-to-refresh function
          child:Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: checkoutItems.isNotEmpty
                      ? ListView.builder(
                    itemCount: checkoutItems.length,
                    itemBuilder: (context, index) {
                      final item = checkoutItems[index];
                      final cartItems = item['cart_items'] as List;

                      print('showing all your details');
                      print(item);

// Check if the 'user_signature_image' URL is valid
                      final signatureImageAvailable = item['image_user'] == null ||
                          item['image_user'].isEmpty ||
                          item['image_user'] == 'Image empty';

                      if (signatureImageAvailable) {
                        print('image not available');
                      } else {
                        print('Image available');
                      }


                      // Print checkout data
                      print('Checkout Data: $item');
                      return GestureDetector(
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
                                if (cartItems.isEmpty)
                                  Text('No items in this checkout', style: TextStyle(color: Colors.red)),
                                if (cartItems.isNotEmpty)
                                  Column(
                                    children: cartItems.map<Widget>((cartItem) {
                                      final assetDetails = _extractAssetDetails(cartItem['asset']);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Asset Name: ${assetDetails['name'] ?? 'N/A'}'),
                                            Text('Serial Number: ${assetDetails['serial_number'] ?? 'N/A'}'),
                                            Text('KNET Tag: ${assetDetails['kenet_tag'] ?? 'N/A'}'),
                                            Text('Going Location: ${assetDetails['new_location'] ?? 'N/A'}'),
                                            Divider(),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else
                                  Text('No items in the cart.'),
                                // Conditionally render the button
                                if (cartItems.isNotEmpty)
                                ElevatedButton(
                                  onPressed: () {
                                    if (item['image_user'] == null ||
                                        item['image_user'].isEmpty ||
                                        item['image_user'] == 'Image empty') {
                                      // Show Add Signature dialog
                                      _showCheckoutDialog(item['checkout_id']);
                                    } else {
                                      // Show PDF viewing screen (assuming you have a method for this)
                                      _viewPdf(item['checkout_id']);
                                    }
                                  },
                                  child: Text(
                                    item['image_user'] == null ||
                                        item['image_user'].isEmpty ||
                                        item['image_user'] == 'Image empty'
                                        ? 'Add Signature'
                                        : 'View PDF',
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
