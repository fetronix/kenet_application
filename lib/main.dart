import 'package:flutter/material.dart';
import 'package:kenet_application/allUrls.dart';
import 'login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Import for Platform class
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
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

class VersionCheckScreen extends StatefulWidget {
  @override
  _VersionCheckScreenState createState() => _VersionCheckScreenState();
}

class _VersionCheckScreenState extends State<VersionCheckScreen> {
  final String latestVersionUrl = ApiUrls.Appversion;
  String latestVersion = "0.0.0";

  @override
  void initState() {
    super.initState();
    _showPlatformSnackbar();
    _checkForUpdate();
  }

  // Display a snackbar with the platform information
  void _showPlatformSnackbar() {
    String platform = "";
    if (Platform.isAndroid) {
      platform = "Android";
    } else if (Platform.isIOS) {
      platform = "iOS";
    } else if (Platform.isLinux) {
      platform = "Linux";
    } else if (Platform.isWindows) {
      platform = "Windows";
    } else if (Platform.isMacOS) {
      platform = "macOS";
    } else if (Platform.isFuchsia) {
      platform = "Fuchsia";
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Running on $platform")),
      );
    });
  }

  // Check if the app version is outdated
  void _checkForUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    try {
      final response = await http.get(Uri.parse(latestVersionUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        latestVersion = data['latest_version'];
        String updateUrl = data['update_url'];

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          _showUpdateDialog(updateUrl);
        } else {
          _navigateToLogin();
        }
      } else {
        print("Failed to load the latest version from server");
      }
    } catch (e) {
      print("Error fetching the latest version: $e");
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    return currentVersion != latestVersion;
  }

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

  void _launchUpdateURL(String updateUrl) async {
    if (await canLaunch(updateUrl)) {
      await launch(updateUrl);
    } else {
      throw 'Could not launch $updateUrl';
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checking for Updates...")),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
