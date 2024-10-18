import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/Consignmentreceiving.dart';
import 'package:kenet_application/addDelivery.dart';
import 'package:kenet_application/assetreceiving.dart';// Import the Deliveries page
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String accessToken;
  final String refreshToken;

  const HomeScreen({
    Key? key,
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _assets = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final url = 'http://197.136.16.164:8000/app/api/assets/'; // Update with your actual API endpoint

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}', // Use the access token for authentication
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _assets = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load assets. Status code: ${response.statusCode}';
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

  void _navigateToAssetCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetReceiving(title: "Asset Receiving")), // Ensure you have this screen implemented
    );
  }

  void _navigateToDeliveries() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryReceiving(title: "Consignment")), // Navigate to the Deliveries page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToAssetCreation, // Navigate to the asset creation screen
          ),
          IconButton(
            icon: Icon(Icons.local_shipping), // Add an icon for deliveries
            onPressed: _navigateToDeliveries, // Navigate to the deliveries screen
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : ListView.builder(
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          final asset = _assets[index];
          return ListTile(
            title: Text(asset['asset_description'] ?? 'No description'),
            subtitle: Text('Serial Number: ${asset['serial_number'] ?? 'N/A'}'),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Handle edit action here (you might want to navigate to an edit screen)
              },
            ),
          );
        },
      ),
    );
  }
}
