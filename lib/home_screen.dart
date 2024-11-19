import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/addDelivery.dart';
import 'package:kenet_application/adminpage.dart';
import 'package:kenet_application/allUrls.dart';
import 'package:kenet_application/delivery_screen.dart';
import 'package:kenet_application/faulty_assets.dart';
import 'package:kenet_application/settings.dart';
import 'package:kenet_application/shared_pref_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'assetreceiving.dart'; // Import the asset receiving screen
import 'cart.dart';
import 'checkout_screen.dart';
import 'login_screen.dart'; // Import the cart screen
import 'package:webview_flutter/webview_flutter.dart';

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
  List<dynamic> _filteredAssets = [];
  List<dynamic> _cart = []; // Cart to hold selected assets
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _searchController.addListener(_filterAssets);
  }

  Future<void> _fetchAssets() async {
    final url = ApiUrls.assetList;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedAssets = jsonDecode(response.body);

        setState(() {
          _assets = fetchedAssets;
          _filteredAssets = fetchedAssets;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load assets. Status code: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _filterAssets() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredAssets = _assets.where((asset) {
        return asset['serial_number'].toLowerCase().contains(query) ||
            asset['kenet_tag'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Ensure the asset ID is converted to a string when constructing the URL
  Future<void> _updateAssetStatus(int assetId, String newStatus) async {
    final updateUrl = ApiUrls.getAssetDetail(assetId);
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        print('Asset status updated successfully.');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Asset status updated to $newStatus')),
        // );
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Failed to update asset status: ${response.statusCode}, ${errorResponse['detail']}');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to update asset status: ${errorResponse['detail']}')),
        // );
      }
    } catch (e) {
      // print('Error updating asset status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating asset status: $e')),
      );
    }
  }

// Also update in the show dialog function
  void _showLocationUpdateDialog(dynamic asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asset: ${asset['asset_description']}'),
          content: asset['status'] == 'instore'
              ? Text('This asset is currently in store. Would you like to add it to the cart and mark it as pending release?')
              : Text('This asset is not In store kindly check other Items'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            if (asset['status'] == 'instore')
              ElevatedButton(
                onPressed: () async {
                  await _addToCart(asset['id']);
                  await _updateAssetStatus(asset['id'], 'pending_release'); // Pass asset['id'] as integer here
                  Navigator.of(context).pop(); // Close the dialog after action
                },
                child: Text('Add to Cart'),
              ),
          ],
        );
      },
    );
  }


  Future<void> _addToCart(int assetId) async {
    final url = ApiUrls.addToCart(assetId);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        // Successfully added to cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added asset to dispatch basket, You have 24hrs before your items are deleted automatically')),
        );
      } else {
        // Handle errors
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The Asset is already in dispatch basket: ${errorResponse['detail']}')),
        );
      }
    } catch (e) {
      // Handle network errors
      // print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }


  // Logout function

    // Logout function to clear tokens and navigate to login
    Future<void> _logoutUser() async {
      SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
      await sharedPrefHelper.clearAllData(); // Assuming this clears stored tokens and user data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }




  void _navigateToAssetReceiving() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetReceiving(title: 'fd',)),
    );
  }
  void _navigateToConsignmentReceiving() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryReceiving(title: 'fd',)),
    );
  }

  // Function to navigate to the cart screen
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(accessToken:widget.accessToken),
      ),
    );
  }


  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Image.asset(
                'assets/images/logo.png', // Replace with your logo asset path
                height: 100, // Adjust the height as needed
              ),
              Divider(), // Divider below the logo
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuButton('Return Faulty/Decommissioned Asset', Icons.bus_alert_sharp, () {
                // Navigate to add assets page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaultyScreen(title: '',accessToken:widget.accessToken)),
                );
              }),
              SizedBox(height: 10),
              _buildMenuButton('Add Assets', Icons.add_circle, () {
                // Navigate to add assets page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssetReceiving(title: 'fd')),
                );
              }),
              SizedBox(height: 10),
              _buildMenuButton('Cart', Icons.shopping_cart, () {
                // Handle Cart tap
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen(accessToken: widget.accessToken)),
                );
              }),
              SizedBox(height: 10),
              _buildMenuButton('View Consignment', Icons.view_agenda, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveriesScreen(accessToken: widget.accessToken)),
                );
              }),
              SizedBox(height: 10),
              _buildMenuButton('Logout', Icons.logout, () {
                _logoutUser(); // Call your logout function
                Navigator.of(context).pushReplacementNamed('/login');
              }),
              SizedBox(height: 10),
              _buildMenuButton('Checkout Screen', Icons.book, () {
                // Handle Checkout Screen tap
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      id: widget.id,
                      username: widget.username,
                      firstName: widget.firstName,
                      lastName: widget.lastName,
                      email: widget.email,
                      accessToken: widget.accessToken,
                      refreshToken: widget.refreshToken,
                    ),
                  ),
                );
              }),
              SizedBox(height: 10),
              // Conditionally show the "Admin View" button if the user role is "network_admin"
              if (widget.role == 'can_checkout_items')
                _buildMenuButton('Verify Dispatch Items', Icons.admin_panel_settings, () {
                  // Navigate to the Admin View page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminScreen(
                        id: widget.id,
                        username: widget.username,
                        firstName: widget.firstName,
                        lastName: widget.lastName,
                        email: widget.email,
                        accessToken: widget.accessToken,
                        refreshToken: widget.refreshToken,
                      ),
                    ),
                  );
                }),
              SizedBox(height: 10),
              // New button to open the external URL
              if (widget.role == 'can_checkout_items')
              _buildMenuButton('Admin Portal', Icons.link, () {
                _openExternalURL();
              }),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _openExternalURL() async {
    const url = ApiUrls.adminportal;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }




// Method to build a rounded button with an icon
  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, // Ensures the button takes full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ), backgroundColor: Colors.white,
          side: BorderSide(
            color: Color(0xFF653D82),
            width: 2, // Increase border width
          ), // Background color
          padding: EdgeInsets.symmetric(vertical: 12), // Button padding
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center align the content
          children: [
            Icon(icon, color: Color(0xFF653D82)), // Icon color
            SizedBox(width: 8), // Space between icon and text
            Text(
              title,
              style: TextStyle(color: Color(0xFF653D82)), // Text color
            ),
          ],
        ),
        onPressed: onTap,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Welcome back, ${widget.username}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Color(0xFF653D82),
          actions: [
            IconButton(
              iconSize: 30,
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.shopping_cart,
                  size: 30,
                  color: Colors.black,
                ),

              ),
              onPressed: _navigateToCart, // Navigate to the cart
            ),
            IconButton(
              iconSize: 40, // Increase the size of the icon
              icon: Container(
                padding: EdgeInsets.all(8), // Add padding for a better touch target
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent, // Keep background transparent
                ),
                child: Icon(
                  Icons.menu,
                  size: 30, // You can also adjust this size if needed
                  color: Colors.white, // Set the icon color to white
                ),
              ),
              onPressed: _showMenuDialog, // Show the menu dialog
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8A2BE2),
                Color(0xFF8A2BE2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _fetchAssets,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Serial Number or KENET Tag...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear(); // Clear the input field
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Color(0xFF653D82), width: 2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : ListView.builder(
                    itemCount: _filteredAssets
                        .where((asset) => asset['status'] == 'instore')
                        .length,
                    itemBuilder: (context, index) {
                      // Filter the assets with status "in store"
                      final filteredAssets = _filteredAssets
                          .where((asset) => asset['status'] == 'instore')
                          .toList();
                      final asset = filteredAssets[index];

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: GestureDetector(
                          onTap: () => _showLocationUpdateDialog(asset),
                          child: ListTile(
                            title: Text(
                              asset['asset_description'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold, // Highlight description
                              ),
                            ),
                            subtitle: Text(
                              'Serial Number: ${asset['serial_number']} | '
                                  'Kenet Tag: ${asset['kenet_tag']} | '
                                  'Location Received: ${asset['location']['name']} | '
                                  'Asset Status: ${asset['status']}',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.shopping_basket_outlined),
                              onPressed: () => _showLocationUpdateDialog(asset),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

