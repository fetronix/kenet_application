import 'package:flutter/material.dart';
import 'package:kenet_application/allUrls.dart';
import 'login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KENET Assets',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VersionCheckScreen(),
      routes: {
        '/login': (context) => LoginScreen(), // Adjust the widget name as necessary
      },
    );
  }
}

class VersionCheckScreen extends StatefulWidget {
  @override
  _VersionCheckScreenState createState() => _VersionCheckScreenState();
}

class _VersionCheckScreenState extends State<VersionCheckScreen> {
  // URL of your Django API endpoint that returns the latest version
  final String latestVersionUrl = ApiUrls.Appversion;

  String latestVersion = "0.0.0"; // Default version in case of an error

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  // Check if the app version is outdated
  void _checkForUpdate() async {
    // Get the current version of the app
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    // Fetch the latest version from your server
    try {
      final response = await http.get(Uri.parse(latestVersionUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        latestVersion = data['latest_version']; // Get the latest version
        String updateUrl = data['update_url']; // Get the update URL

        // Compare versions
        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          // Show the update dialog if an update is available
          _showUpdateDialog(updateUrl);
        } else {
          // If the version is up-to-date, navigate to the login screen
          _navigateToLogin();
        }
      } else {
        print("Failed to load the latest version from server");
      }
    } catch (e) {
      print("Error fetching the latest version: $e");
    }
  }

  // Compare current app version with the latest version
  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    return currentVersion != latestVersion;
  }

  // Show the dialog to update the app
  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Required"),
        content: Text("A new version of the app is available. Please update to continue."),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _launchUpdateURL(updateUrl);
            },
            child: Text("Update Now"),
          ),
        ],
      ),
    );
  }

  // Launch the app update URL (e.g., your server's URL for APK download)
  void _launchUpdateURL(String updateUrl) async {
    if (await canLaunch(updateUrl)) {
      await launch(updateUrl);
    } else {
      throw 'Could not launch $updateUrl';
    }
  }

  // Navigate to the login screen if the app is up-to-date
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return a loading screen while checking for the update
    return Scaffold(
      appBar: AppBar(title: Text("Checking for Updates...")),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
