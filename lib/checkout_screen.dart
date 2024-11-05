import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final String accessToken;

  const CheckoutScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<dynamic> checkoutItems = [];
  bool isLoading = true;
  String userDetails = ""; // Variable to hold user details

  @override
  void initState() {
    super.initState();
    _fetchCheckoutItems();
    _loadUserDetails(); // Load user details from SharedPreferences
  }

  Future<void> _fetchCheckoutItems() async {
    final url = 'http://197.136.16.164:8000/app/checkouts/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
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
      print('Error fetching checkout items: $e');
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
      print(userDetails);
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    return Scaffold(
      appBar: AppBar(title: Text('Checkout Items')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('User Details: $userDetails',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: checkoutItems.isNotEmpty
                ? ListView.builder(
              itemCount: checkoutItems.length,
              itemBuilder: (context, index) {
                final item = checkoutItems[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checkout ID: ${item['checkout_id']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('User: ${item['username']}'), // Display username instead of user ID
                        Text('Checkout Date: ${item['checkout_date'].toString()}'),
                        Text('Remarks: ${item['remarks']}'),
                        Divider(),
                        Text('Cart Items:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['name']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['serial_number']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['kenet_tag']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['location_received']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['status']),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(assetDetails['new_location']),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          )
                        else
                          Text('No items in cart.'),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(child: Text('No checkout items available.')),
          ),
        ],
      ),
    );
  }
}
