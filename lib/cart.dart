import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/allUrls.dart';
import 'package:kenet_application/shared_pref_helper.dart';

class CartScreen extends StatefulWidget {
  final String accessToken;

  const CartScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];


  // Define a hardcoded list of locations
  final String locationApiUrl = ApiUrls.locationApiUrl;
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchLocations();
    _fetchUsers();
    _filteredLocations = _locations;
    _filteredUsers = _users;
  }

  Future<void> _fetchLocations() async {
    
    print("FETCHING LOCATIONS");
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

    print("DONE FETCHING LOCATIONS");
  }

  void _filterLocations(String query) {
    final filtered = _locations.where((location) {
      return location['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredLocations = filtered;
    });
  }


  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(ApiUrls.usersadminurl));

      if (response.statusCode == 200) {
        List<dynamic> usersList = jsonDecode(response.body);

        // Debugging: Print the raw response
        print('Raw Users Data: ${response.body}');

        // Retrieve the logged-in user's ID using SharedPrefHelper
        final String? loggedInUserId = await SharedPrefHelper().getUserId();

        // Ensure the ID is not null before proceeding
        if (loggedInUserId == null) {
          throw Exception('Logged-in user ID not found');
        }

        // Filter out the logged-in user
        List<Map<String, dynamic>> filteredUsers = usersList
            .where((user) => user['id'].toString() != loggedInUserId) // Exclude logged-in user
            .map((user) => {
          'id': user['id'],
          'username': user['username'],
          'name': user['first_name'] + " " + user['last_name'], // Use 'name' consistently
        })
            .toList();

        setState(() {
          _users = filteredUsers;

          // Debugging: Print the processed users list
          print('Processed Users List: $_users');

          _filteredUsers = _users;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Users: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle errors gracefully
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }



  void _filterusers(String query) {
    final filtered = _users.where((user) {
      return user['first_name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredUsers = filtered;
    });
  }



  Future<void> _fetchCartItems() async {
    final url = ApiUrls.cartList;
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
            return {
              'id': item['id'],
              'user': item['user'],
              'asset_name': assetDetails['name'],
              'serial_number': assetDetails['serial_number'],
              'kenet_tag': assetDetails['kenet_tag'],
              'location_received': assetDetails['location_received'],
              'new_location': assetDetails['going_location'],
              'status': assetDetails['status'],
              'AssetId': assetDetails['AssetId'],
            };
          }).toList();
        });
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

  Future<void> _checkout(String location, String verify_user) async {
    final checkoutUrl = ApiUrls.checkoutDetail;
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
          'new_location': location,
          'verified_user':verify_user, // Include new location in the request body
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

  void _showCheckoutDialog() {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: location,
                      child: Text(
                        location['name'] ?? "No Name Available", // Ensure there's a fallback value
                        overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                        maxLines: 1, // Restrict to a single line
                      ),
                    );
                  }).toList(),
                  isExpanded: true, // Make sure the dropdown stretches to fit the available space
                  decoration: InputDecoration(
                    border: InputBorder.none, // Remove default border
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Add padding if needed
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  hint: const Text('Select verifier'),
                  value: _user,
                  onChanged: (value) {
                    setState(() {
                      _user = value;
                    });
                  },
                  items: _filteredUsers.map((user) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: user,
                      child: Text(
                        user['name'] ?? "No Name Available", // Match the key used in _fetchUsers
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Text('Are you sure you want to proceed with the checkout?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_location!['name'] != null || _user!['username']  != null) {
                  await _checkout(_location!['name'], _user!['username']);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a location')),
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
  Widget build(BuildContext context) {
    final pendingCartItems = cartItems.where((item) => item['status'] == 'pending_release').toList();

    return Scaffold(
      appBar: AppBar(title: Text('Dispatch Basket')),
      body: pendingCartItems.isNotEmpty
          ? Column(

        children: [
          Expanded(
              child: RefreshIndicator(
              onRefresh: _fetchCartItems,
            child:
            ListView.builder(
              itemCount: pendingCartItems.length,
              itemBuilder: (context, index) {
                final item = pendingCartItems[index];
                return ListTile(
                  title: Text(item['asset_name']),
                  subtitle: Text('Serial: ${item['serial_number']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAssetFromCart(item['id']),
                  ),
                );
              },
            ),)
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
    final url = ApiUrls.removecart(assetId);
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
          SnackBar(content: Text('Asset removed from cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove asset from cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing asset from cart: $e')),
      );
    }
  }
}
