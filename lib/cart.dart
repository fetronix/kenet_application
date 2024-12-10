import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/allUrls.dart';
import 'package:kenet_application/shared_pref_helper.dart';

import 'location.dart';

class CartScreen extends StatefulWidget {
  final String accessToken;

  const CartScreen({super.key, required this.accessToken});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];


  // Define a hardcoded list of locations
  final String locationApiUrl = ApiUrls.locationApiUrl;
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _user;
  final List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _filteredLocations = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();
  int _selectedLocationId = 0; // Initialize as an int
  Timer? _debounce;
  late List<Location> _searchResults = []; //as Future<List<Location>>;
  bool _isLoading = false;
  bool _isSelected = false;
  late String location = '';
  String? _selectedLocation; // Holds the selected location
  final String locationsUrl = 'http://197.136.16.164:8000/app/api/locations/?search=';
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();



  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchUsers();
    _filteredUsers = _users;

    _searchController.addListener(() {
      _onSearchChanged();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _overlayEntry?.remove();

    super.dispose();
  }

  void _onSearchChanged() {
    // print("search cnahed");

    _removeOverlay();


    if (_isSelected) {
      _isSelected = false;
      return;
    }

    _searchResults = [];
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      print(_searchController.text);

      if (location == _searchController.text) {
        return;
      }

      if (_searchController.text.isNotEmpty) {
        _fetchAllLocations(_searchController.text);
      } else {
        setState(() {
          _searchController.clear();
        });
      }
    });
  }


  Future<void> _fetchAllLocations(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$locationsUrl$query"));

      if (response.statusCode == 200) {
        List<dynamic> locations = jsonDecode(response.body);
        final List<Location> locationsList = locations.map((json) => Location.fromJson(json)).toList();
        print("LETS SEE LOCATIONS");
        print(locationsList);

        for (var y in locationsList) {
          print('${y.id}' '${y.name}' '${y.nameAlias}');
        }

        setState(() {
          _searchResults = locationsList;
        });

        // return locationsList;
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (error) {
      print(error.toString());

      setState(() {
        _searchResults = [];
      });

      // return [];
    } finally {
      setState(() {
        _isLoading = false;
      });

      if (_overlayEntry == null) {
        _showOverlay(context);
      } else {
        _updateOverlay();
      }
    }
  }
  void _showOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
            width: MediaQuery.of(context).size.width - 40,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(50, 50),
              child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit height to 50% of screen
                    ),
                    child: _isLoading
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : ListView.builder(
                        padding: const EdgeInsets.all(4),
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          if (index < _searchResults.length) {
                            return ListTile(
                                title: Text(_searchResults[index].name),
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  _isSelected = true;
                                  _searchController.text = _searchResults[index].name;
                                  _selectedLocationId = _searchResults[index].id; // Ensure it's a string
                                  print("The location is: ");
                                  print(_searchController.text);
                                  print("The id is .....");
                                  print(_selectedLocationId);
                                  _removeOverlay();

                                });
                          }
                          return const Text('search entry not found');
                        }),
                  )),
            )));

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
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

  Future<void> _checkout(String location, String verifyUser) async {
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
          'verified_user':verifyUser, // Include new location in the request body
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

              const SizedBox(height: 16),
              CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: 'Search and select location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)), // Rounded corners
                      borderSide: BorderSide(
                        color: Colors.grey, // Border color
                        width: 1.5, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide(
                        // color: Colors.blue, // Border color when focused
                        width: 2.0, // Border width when focused
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), // Padding inside the box
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
                if (_searchController.text != null || _user!['username']  != null) {
                  await _checkout(_searchController.text, _user!['username']);
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
