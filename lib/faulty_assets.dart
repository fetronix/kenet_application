import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/addDelivery.dart';
import 'package:kenet_application/adminpage.dart';
import 'package:kenet_application/allUrls.dart';
import 'package:kenet_application/delivery_screen.dart';
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

class FaultyScreen extends StatefulWidget {

  final String accessToken;

  const FaultyScreen({
    Key? key, required String title,required this.accessToken
  }) : super(key: key);

  @override
  _FaultyScreenState createState() => _FaultyScreenState();
}

class _FaultyScreenState extends State<FaultyScreen> {
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

  Future<void> _updateAssetStatus(int assetId) async {
    final updateUrl = ApiUrls.faultyAssetDetail(assetId);
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': "faulty"}),
      );

      if (response.statusCode == 200) {
        print('Asset status updated successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset return and marked as faulty successfully.')),
        );
      } else {
        print('Failed to update asset status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating asset status: $e');
    }
  }

  Future<void> _DecommissionupdateAssetStatus(int assetId) async {
    final updateUrl = ApiUrls.decommissionedAssetDetail(assetId);
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': "decommissioned"}),
      );

      if (response.statusCode == 200) {
        print('Asset status updated successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset return and marked as decommissioned successfully.')),
        );
      } else {
        print('Failed to update asset status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating asset status: $e');
    }
  }

  void _showLocationUpdateDialog(dynamic asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asset: ${asset['asset_description']}'),
          content: asset['status'] == 'faulty' || asset['status'] == 'decommissioned'
              ? Text('This asset is already faulty or decommissioned. Kindly check other items.')
              : Text('Do you want to return this asset and mark it as Faulty or Decommissioned?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            // Show the Faulty Asset button only if it's not already faulty
            if (asset['status'] != 'faulty' && asset['status'] != 'decommissioned')
              ElevatedButton(
                onPressed: () async {
                  await _updateAssetStatus(asset['id']); // Pass asset['id'] as integer here
                  Navigator.of(context).pop(); // Close the dialog after action
                },
                child: Text('Faulty Asset'),
              ),
            // Show the Decommission Asset button only if it's not already decommissioned
            if (asset['status'] != 'decommissioned' && asset['status'] != 'faulty')
              ElevatedButton(
                onPressed: () async {
                  await _DecommissionupdateAssetStatus(asset['id']); // Pass asset['id'] as integer here
                  Navigator.of(context).pop(); // Close the dialog after action
                },
                child: Text('Decommission Asset'),
              ),
          ],
        );
      },
    );
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
              'Return faulty or decommissioned Asset',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Color(0xFF653D82),
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
                        child: GestureDetector(
                          onTap: () => _showLocationUpdateDialog(asset), // Show dialog on item tap
                          child: ListTile(
                            title: Text(asset['asset_description'], style: TextStyle(
                              fontWeight: FontWeight.bold,  // Make asset description bold for some statuses
                            ),),
                            subtitle: Text('Serial Number: ${asset['serial_number']} | Kenet Tag: ${asset['kenet_tag']}| Location Received: ${asset['location']['name']}  | Asset Status: ${asset['status']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.bus_alert_sharp),
                              onPressed: () => _showLocationUpdateDialog(asset), // Show dialog when icon is clicked
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

