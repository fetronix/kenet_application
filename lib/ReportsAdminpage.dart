import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/allUrls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AdminReportScreen extends StatefulWidget {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String accessToken;
  final String refreshToken;

  const AdminReportScreen({
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
  _AdminReportScreenState createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
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
    final url = ApiUrls.checkoutList;

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
        print(response.body);

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
              'pdf_file': item['pdf_file'] ?? 'No files',
              'cart_items': cartItems,

            };
          }).toList();
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

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userDetails'); // Clear stored user details
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login page
  }

  Future<void> _approveCheckout(int checkoutId) async {
    final url = ApiUrls.approveCheckoutDetail(checkoutId);

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

  Future<void> _rejectCheckout(int checkoutId) async {
    final url = ApiUrls.rejectCheckoutDetail(checkoutId);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSnackbar('Dispatch rejected successfully.');
        _fetchCheckoutItems(); // Refresh the list after approval
      } else {
        _showSnackbar('Failed to reject checkout: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Error rejecting checkout: $e');
    }
  }

  void _showApprovalDialog(int checkoutId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Approve/Reject Users Dispatch'),
          content: Text('Do you want to Approve or Reject this Dispacth?'),
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _rejectCheckout(checkoutId); // Call the approval function
              },
              child: Text('Reject'),
            ),
          ],
        );
      },
    );
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
          title: Text('Update The Approved Checkout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please Add your Signature to Verify'),
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
                  'quantity_required': totalItems,
                  'quantity_issued': totalItems,
                  'authorizing_name': widget.email,
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
    final url = ApiUrls.updateCheckoutDetail(checkoutId); // Update with your actual URL
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
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
                      final cartItems = item['cart_items'] as List;
                      final hasOnSiteStatus = item['cart_items'].any((cartItem) {
                        final assetDetails = _extractAssetDetails(cartItem['asset']);
                        return assetDetails['status'] == 'onsite';
                      });
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
                                Text('Dispatched Date: ${formatDate(item['checkout_date'])}'),
                                item['pdf_file'] != null
                                    ? GestureDetector(
                                  onTap: () async {
                                    String pdfUrl = item['pdf_file'];
                                    if (await canLaunch(pdfUrl)) {
                                      await launch(pdfUrl); // Opens the PDF in the browser or external PDF viewer
                                    } else {
                                      throw 'Could not open the PDF file.';
                                    }
                                  },
                                  child: Text(
                                    'View PDF',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                                    : Container(),
                                Divider(),
                                ]
                            ),
                          ),
                        ),
                      );
                    },
                  )
                      : Center(child: Text('No checkout items available.')),
                )
,
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatDate(dynamic date) {
    // Check if the date is already a DateTime object
    DateTime parsedDate;
    if (date is String) {
      parsedDate = DateTime.parse(date); // If it's a string, parse it
    } else if (date is DateTime) {
      parsedDate = date; // If it's already a DateTime, use it directly
    } else {
      return 'Invalid date'; // Handle invalid date types
    }

    // Format the DateTime object
    String formattedDate = DateFormat('MMMM d, yyyy').format(parsedDate);
    return formattedDate;
  }


}
