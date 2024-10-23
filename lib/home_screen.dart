import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'assetreceiving.dart'; // Make sure to import the asset receiving screen

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
  List<dynamic> _cart = [];
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
          _errorMessage =
          'Failed to load assets. Status code: ${response.statusCode} - ${response.body}';
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

  // Function to show a pop-up dialog for location update
  void _showLocationUpdateDialog(dynamic asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Location for ${asset['asset_description']}'),
          content: TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Enter New Location'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateAssetLocation(asset);
              },
              child: Text('Add to Cart'),
            ),
          ],
        );
      },
    );
  }

  // Function to update the asset location and status
  Future<void> _updateAssetLocation(dynamic asset) async {
    final newLocation = _locationController.text.trim();
    if (newLocation.isEmpty) return;

    final url = 'http://197.136.16.164:8000/app/assets/${asset['id']}/';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'pending_release',
          'location': newLocation,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update the asset locally to reflect changes
          asset['location']['name'] = newLocation;
          asset['status'] = 'pending_release';

          // Add to cart if not already added
          if (!_cart.contains(asset)) {
            _cart.add(asset);
          }

          _locationController.clear();
        });
        Navigator.of(context).pop(); // Close the dialog
      } else {
        print('Failed to update asset: ${response.body}');
      }
    } catch (e) {
      print('Error updating asset: $e');
    }
  }

  // Navigate to Asset Receiving Screen
  void _navigateToAssetReceiving() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetReceiving(title: 'fd',)),
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
              iconSize: 30, // This is the size of the IconButton itself
              icon: Container(
                padding: EdgeInsets.all(8), // Optional padding for a larger touch target
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Background color of the icon
                ),
                child: Icon(
                  Icons.shopping_cart,
                  size: 30, // Size of the icon
                  color: Colors.black, // Change to black or any color you prefer
                ),
              ),
              onPressed: () {
                // Navigate to cart page or show cart items
              },
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
                  child:OutlinedButton.icon(
                    onPressed: _navigateToAssetReceiving,
                    icon: Icon(Icons.add, color: Color(0xFF653D82)), // Set icon color to match the button color
                    label: Text('Add New Asset', style: TextStyle(color: Color(0xFF653D82))), // Set text color to match
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white, // Background color (optional, can be transparent)
                      side: BorderSide(color: Color(0xFF653D82), width: 2), // Outline color and width
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Added horizontal padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // Rounded borders
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
                        margin: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            'Asset: ${asset['asset_description']}',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            'Serial: ${asset['serial_number']} | Tag: ${asset['kenet_tag']} | Location: ${asset['location']['name']}',
                            style: TextStyle(color: Colors.black),
                          ),
                          trailing: Text(
                            'Status: ${asset['status']}',
                            style: TextStyle(
                              color: asset['status'] ==
                                  'pending_release'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          onTap: () {
                            // Show the location update pop-up when item is clicked
                            _showLocationUpdateDialog(asset);
                          },
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
