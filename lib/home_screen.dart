import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/addDelivery.dart';
import 'package:kenet_application/delivery_screen.dart';
import 'package:kenet_application/release_form.dart';
import 'package:kenet_application/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'assetreceiving.dart'; // Import the asset receiving screen
import 'cart.dart'; // Import the cart screen

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
    final url = 'http://197.136.16.164:8000/app/api/assets/';

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

  void _showLocationUpdateDialog(dynamic asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asset: ${asset['asset_description']}'),
          content: asset['status'] == 'pending_release'
              ? Text('This asset is pending release. Would you like to add it to the cart?')
              : TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Enter New Location'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            asset['status'] == 'pending_release'
                ? ElevatedButton(
              onPressed: () {
                _addToCart(asset['id']);
                Navigator.of(context).pop(); // Close the dialog after action
              },
              child: Text('Add to Cart'),
            )
                : ElevatedButton(
              onPressed: () {
                _updateAssetLocation(asset);
                Navigator.of(context).pop(); // Close the dialog after action
              },
              child: Text('Update Location'),
            ),
          ],
        );
      },
    );
  }

  // Logout function
  void _logoutUser() async {
    // Clear user session or token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken'); // Adjust the key as necessary
    // Any other necessary cleanup can be done here
  }

  Future<void> _updateAssetLocation(dynamic asset) async {
    final newLocation = _locationController.text.trim();
    if (newLocation.isEmpty) return;

    // Step 1: Update the asset location and status
    final updateUrl = 'http://197.136.16.164:8000/app/assets/${asset['id']}/';
    try {
      final updateResponse = await http.put(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'pending_release',
          'new_location': newLocation,
        }),
      );

      if (updateResponse.statusCode == 200) {
        // Successfully updated location and status
        setState(() {
          asset['new_location'] = newLocation;
          asset['status'] = 'pending_release';
          _locationController.clear();
        });

        // Show snackbar for successful update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated asset location and status')),
        );
      } else {
        // Handle update failure
        final errorResponse = jsonDecode(updateResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update asset: ${errorResponse['error']}')),
        );
      }
    } catch (e) {
      print('Error updating asset: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating asset: $e')),
      );
    }
  }


  Future<void> _addToCart(int assetId) async {
    final url = 'http://197.136.16.164:8000/app/cart/add/$assetId/';
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
          SnackBar(content: Text('Successfully added asset to dispatch basket')),
        );
      } else {
        // Handle errors
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The Asset is Already in dispatch basket')),
        );
      }
    } catch (e) {
      // Handle network errors
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        // SnackBar(content: Text('Error adding to cart: $e')),
        SnackBar(content: Text('The Asset is Already in dispatch basket')),
      );
    }
  }


  void _navigateToAssetReceiving() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetReceiving(title: 'fd',)),
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
              _buildMenuButton('Add Assets', Icons.add_circle, () {
                // Navigate to add assets page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssetReceiving(title: 'fd',)),
                );
              }),
              SizedBox(height: 10), // Add spacing between buttons
              _buildMenuButton('Cart', Icons.shopping_cart, () {
                // Handle Cart tap
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen(accessToken:widget.accessToken)),
                );
              }),
              SizedBox(height: 10), // Add spacing between buttons
              _buildMenuButton('Add Consignment', Icons.assignment_add, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveryReceiving(title:'')),
                );
              }),
              SizedBox(height: 10),
              _buildMenuButton('View Consignment', Icons.view_agenda, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveriesScreen(accessToken:widget.accessToken)),
                );
              }),
              SizedBox(height: 10), // Add spacing between buttons
              _buildMenuButton('Release Form', Icons.book, () {
                // Handle Settings tap
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReleaseForm()),
                );
              }),
              SizedBox(height: 10), // Add spacing between buttons
              _buildMenuButton('Logout', Icons.logout, () {
                _logoutUser(); // Call your logout function
                Navigator.of(context).pushReplacementNamed('/login');
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
                Color(0xFF6A5ACD),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: _navigateToAssetReceiving,
                    icon: Icon(Icons.add, color: Color(0xFF653D82)),
                    label: Text('Add New Asset', style: TextStyle(color: Color(0xFF653D82))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Color(0xFF653D82), width: 2),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
                    itemCount: _filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = _filteredAssets[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(asset['asset_description']),
                          subtitle: Text('Serial Number: ${asset['serial_number']}|Location Received : ${asset['location']['name']}|Location Going : ${asset['new_location']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showLocationUpdateDialog(asset),
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
