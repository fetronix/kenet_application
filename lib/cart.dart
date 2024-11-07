import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  final String accessToken;

  const CartScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    final url = 'http://197.136.16.164:8000/app/cart/';
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
          cartItems = jsonResponse.map<Map<String, dynamic>>((item) {
            final assetDetails = _extractAssetDetails(item['asset']);
            final addedAt = DateTime.parse(item['added_at']);
            final countdown = _calculateCountdown(addedAt);
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
              'added_at': addedAt,
              'countdown': countdown,
            };
          }).toList();
        });
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch cart items')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cart items: $e')),
      );
    }
  }

  Future<void> _checkout(String newLocation) async {
    final checkoutUrl = 'http://197.136.16.164:8000/app/checkout/';
    // Filter cartItems to include only those with status 'pending_release'
    final itemsForCheckout = cartItems
        .where((item) => item['status'] == 'pending_release')
        .map((item) => item['id'])
        .toList();

    if (itemsForCheckout.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No items with status "pending_release" in the cart')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(checkoutUrl),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cart_items': itemsForCheckout,
          'new_location': newLocation, // Include new location in the request body
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          cartItems.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during checkout: $e')),
      );
    }
  }



  int _calculateCountdown(DateTime addedAt) {
    const duration = 30; // 5 minutes in seconds
    final now = DateTime.now();
    final elapsed = now.difference(addedAt).inSeconds;
    return (duration - elapsed).clamp(0, duration);
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        for (var item in cartItems) {
          if (item['status'] == 'pending_release' && item['countdown'] > 0) {
            item['countdown']--;
          }
        }
      });
    });
  }
  void _showCheckoutDialog() {
    final TextEditingController locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'New Location',
                  hintText: 'Enter the new location',
                ),
              ),
              SizedBox(height: 16.0),
              Text('Are you sure you want to proceed with the checkout?'),
            ],
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
                final newLocation = locationController.text.trim();
                if (newLocation.isNotEmpty) {
                  await _checkout(newLocation); // Pass the new location to the checkout method
                  Navigator.of(context).pop(); // Close the dialog after checkout
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a new location')),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCartItems = cartItems.where((item) => item['status'] == 'pending_release').toList();

    return Scaffold(
      appBar: AppBar(title: Text('Dispatch Basket')),
      body: pendingCartItems.isNotEmpty
          ? Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: pendingCartItems.length,
              itemBuilder: (context, index) {
                final item = pendingCartItems[index];
                final countdown = item['countdown'];
                final minutes = countdown ~/ 60;
                final seconds = countdown % 60;
                return ListTile(
                  title: Text(item['asset_name']),
                  subtitle: Text('Serial: ${item['serial_number']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$minutes:${seconds.toString().padLeft(2, '0')}'),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: item['countdown'] > 0
                            ? () => _removeAssetFromCart(item['id'])
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isCheckoutEnabled() ? _showCheckoutDialog : null,
              child: Text('Checkout'),
            ),
          ),
        ],
      )
          : Center(child: Text('No items in the dispatch basket.')),
    );
  }

  bool _isCheckoutEnabled() {
    return cartItems.any((item) => item['status'] == 'pending_release');
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
      'name_model': 'N/A',
    };
  }

  Future<void> _removeAssetFromCart(int assetId) async {
    final url = 'http://197.136.16.164:8000/app/cart/remove/$assetId/';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['id'] == assetId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from dispatch basket successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item from dispatch basket')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item from Dispatch basket: $e')),
      );
    }
  }
}
