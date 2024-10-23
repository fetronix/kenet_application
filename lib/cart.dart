import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  final String accessToken; // Access token for authentication

  const CartScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = []; // List to store cart items

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
            return {
              'id': item['id'], // Store the item ID for removal
              'asset_description': item['asset'], // Adjusted to use asset string directly
              'serial_number': _extractSerialNumber(item['asset']), // Extracted serial number from asset string
              'status': 'pending_release', // Placeholder for status; adjust as necessary
            };
          }).toList();
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

  // Helper method to extract serial number from asset string
  String _extractSerialNumber(String asset) {
    final regex = RegExp(r'\((.*?)\)'); // Extracts text within parentheses
    final match = regex.firstMatch(asset);
    return match != null ? match.group(1) ?? 'N/A' : 'N/A'; // Return extracted serial number or 'N/A'
  }

  // Method to remove an item from the cart
  Future<void> _removeItem(int itemId) async {
    final url = 'http://197.136.16.164:8000/app/cart/remove/$itemId/'; // URL to remove the item
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Successfully removed the item
        setState(() {
          cartItems.removeWhere((item) => item['id'] == itemId); // Remove item from local state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from cart')),
        );
      } else {
        // Handle error response
        print('Failed to remove item: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item')),
        );
      }
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Color(0xFF653D82),
      ),
      body: cartItems.isEmpty
          ? Center(child: Text('Your cart is empty.'))
          : ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final asset = cartItems[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text('Asset Name: ${asset['asset_description']}'),
              subtitle: Text('Serial Number: ${asset['serial_number']}'),
              trailing: Text(
                'Status: ${asset['status']}',
                style: TextStyle(
                  color: asset['status'] == 'pending_release'
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              onTap: () {
                // Show dialog to confirm removal
                _showRemoveDialog(asset['id']);
              },
            ),
          );
        },
      ),
    );
  }

  // Method to show a dialog for confirming the removal of an item
  void _showRemoveDialog(int itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Item'),
          content: Text('Are you sure you want to remove this item from the cart?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _removeItem(itemId); // Call method to remove item
              },
            ),
          ],
        );
      },
    );
  }
}
