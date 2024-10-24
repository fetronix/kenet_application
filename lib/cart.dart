import 'dart:convert';
import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences for local storage

class CartScreen extends StatefulWidget {
  final String accessToken; // Access token for authentication

  const CartScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = []; // List to store cart items
  Timer? _timer; // Timer for countdown
  int _countdown = 0; // Countdown duration in seconds

  @override
  void initState() {
    super.initState();
    _fetchCartItems(); // Fetch cart items when the screen is initialized
  }

  Future<void> _fetchCartItems() async {
    final url = 'http://197.136.16.164:8000/app/cart/'; // URL to fetch cart items
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
        print('Response data: $jsonResponse'); // Debugging log

        setState(() {
          cartItems = jsonResponse.map((item) {
            final assetDetails = _extractAssetDetails(item['asset']);
            return {
              'id': item['id'],
              'user': item['user'],
              'asset_name': assetDetails['name'],
              'serial_number': assetDetails['serial_number'],
              'kenet_tag': assetDetails['kenet_tag'],
              'location_received': assetDetails['location_received'],
              'new_location': assetDetails['new_location'],
              'status': assetDetails['status'],
              'AssetId': assetDetails['AssetId'],
              'added_at': DateTime.parse(item['added_at']), // Parse date item was added
            };
          }).toList();

          // Calculate the initial countdown based on added_at
          _calculateInitialCountdown();
        });
      } else {
        // Handle error response
        print('Failed to fetch cart items: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch cart items')),
        );
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cart items: $e')),
      );
    }
  }

  void _calculateInitialCountdown() {
    if (cartItems.isNotEmpty) {
      // Assuming the countdown duration is 50 seconds (adjust as necessary)
      final duration = 50; // seconds

      // Calculate remaining time for each item based on added_at
      final now = DateTime.now();
      for (var item in cartItems) {
        final addedAt = item['added_at'] as DateTime;
        final elapsed = now.difference(addedAt).inSeconds;
        final remaining = duration - elapsed;

        if (remaining > 0) {
          _countdown = remaining; // Set the countdown to the remaining time
          break; // Only need the first item to set the countdown
        }
      }

      if (_countdown > 0) {
        _startCountdown(); // Start the countdown if there is remaining time
      }
    }
  }

  // Countdown method
  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel(); // Cancel timer when countdown is finished
          _removeAllAssetsFromCart(); // Remove all assets from cart when timer finishes
        }
      });
    });
  }

  // Method to remove all assets from the cart after countdown
  void _removeAllAssetsFromCart() {
    for (var item in cartItems) {
      _editAsset(item['AssetId']); // Edit asset before removing
      _removeAssetFromCart(item['id']);
    }
  }

  // Updated helper method to extract asset details from the asset string
  Map<String, dynamic> _extractAssetDetails(String asset) {
    final regex = RegExp(r'^(.*?)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)\s*\((.*?)\)$');
    final match = regex.firstMatch(asset);

    if (match != null) {
      return {
        'name': match.group(1) ?? 'Unknown',         // Asset name
        'serial_number': match.group(2) ?? 'N/A',    // Serial number
        'kenet_tag': match.group(3) ?? 'N/A',        // KENET tag
        'location_received': match.group(4) ?? 'N/A', // Location received
        'new_location': match.group(5) ?? 'N/A',      // New location
        'status': match.group(6) ?? 'N/A',            // Status
        'AssetId': int.tryParse(match.group(7) ?? '0') ?? 0, // Convert to int
      };
    }
    return {
      'name': 'Unknown',
      'serial_number': 'N/A',
      'kenet_tag': 'N/A',
      'location_received': 'N/A',
      'new_location': 'N/A',
      'status': 'N/A',
      'AssetId': 0, // Default to 0 if parsing fails
    };
  }

  // Method to remove an item from the cart
  void _removeAssetFromCart(int assetId) async {
    final url = 'http://197.136.16.164:8000/app/cart/remove/$assetId/';
    print('Attempting to remove asset with ID: $assetId'); // Log asset ID for reference

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Log status code
      print('Response body: ${response.body}'); // Log response body

      if (response.statusCode == 200) {
        print('Successfully removed asset from dispatch basket');
        setState(() {
          cartItems.removeWhere((item) => item['id'] == assetId); // Update UI by removing item
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from dispatch basket successfully')),
        );
      } else {
        print('Failed to remove asset from cart. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item from dispatch basket')),
        );
      }
    } catch (e) {
      print('Error occurred while removing asset: $e'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item from Dispatch basket: $e')),
      );
    }
  }

  // Method to edit an asset
  void _editAsset(int assetId) async {
    final url = 'http://197.136.16.164:8000/app/assets/$assetId/'; // Ensure the URL is correct
    print('Editing asset with ID: $assetId'); // Log the asset ID

    // Prepare the update payload
    final updateData = jsonEncode({
      'status': 'instore', // Set status to "instore"
      'new_location': null, // Set new_location to null
    });

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: updateData,
      );

      print('Response status: ${response.statusCode}'); // Log response status code
      print('Response body: ${response.body}'); // Log response body

      if (response.statusCode == 200) {
        print('Successfully updated asset status to instore.');
        setState(() {
          // Update the local cartItems list to reflect the changes
          final index = cartItems.indexWhere((item) => item['AssetId'] == assetId);
          if (index != -1) {
            cartItems[index]['status'] = 'instore'; // Update the status locally
          }
        });
      } else {
        print('Failed to update asset. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while editing asset: $e'); // Log any errors
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Build method to render the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dispatch Basket')),
      body: cartItems.isNotEmpty ? Column(
        children: [
          // Display countdown timer
          Text('Time left: ${_countdown}s'),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  title: Text(item['asset_name']),
                  subtitle: Text('Serial: ${item['serial_number']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _removeAllAssetsFromCart(),
                  ),
                );
              },
            ),
          ),
        ],
      ) : Center(child: Text('No items in the dispatch basket.')),
    );
  }
}
