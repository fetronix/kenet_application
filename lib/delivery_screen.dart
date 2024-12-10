import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/addDelivery.dart'; // Import your add delivery screen
import 'package:kenet_application/allUrls.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs

class DeliveriesScreen extends StatefulWidget {
  final String accessToken;

  const DeliveriesScreen({super.key, required this.accessToken});

  @override
  _DeliveriesScreenState createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  List<dynamic> _deliveries = [];
  List<dynamic> _filteredDeliveries = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'instore',
    'tested',
    'default',
    'onsite',
    'pending_release'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
    _searchController.addListener(_filterDeliveries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDeliveries);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveries() async {
    final url = ApiUrls.deliveryallApiUrl; // Update with your actual API endpoint for deliveries

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}', // Use the access token for authentication
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _deliveries = data; // Assuming the root is the list of deliveries
          _filteredDeliveries = _deliveries; // Initialize filtered deliveries
        });
        print('Deliveries fetched: ${_deliveries.length}'); // Debugging line
      } else {
        setState(() {
          _errorMessage = 'Failed to load deliveries. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDeliveries() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDeliveries = _deliveries.where((delivery) {
        return delivery['supplier_name']?.toLowerCase().contains(query) ?? false;
      }).toList();
      print('Filtered deliveries: ${_filteredDeliveries.length}'); // Debugging line
    });
  }

  void _navigateToAddDelivery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryReceiving(title: '')), // Navigate to the AddDeliveryScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deliveries'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Supplier Name...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: _navigateToAddDelivery,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF653D82)), // Change to your desired border color
                foregroundColor: Color(0xFF653D82), // Change to your desired text color
              ),
              child: Text('Add Delivery'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : ListView.builder(
                itemCount: _filteredDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = _filteredDeliveries[index];

                  // Debugging statement to check delivery data
                  print('Delivery item at index $index: $delivery');

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(delivery['supplier_name'] ?? 'No description'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity: ${delivery['quantity'].toString()} | Person Received: ${delivery['person_receiving'] ?? 'N/A'} | Invoice Number: ${delivery['invoice_number'] ?? 'N/A'}',
                          ),
                          delivery['invoice_file'] != null
                              ? GestureDetector(
                            onTap: () {
                              _launchURL(delivery['invoice_file']);
                            },
                            child: Text(
                              'View Invoice',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                              : Text('No Invoice Available'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Handle edit action here (e.g., navigate to edit screen)
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to launch a URL for the invoice file
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
