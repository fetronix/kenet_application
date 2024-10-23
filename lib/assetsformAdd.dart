import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:usb_serial/usb_serial.dart';

class BarcodeScannerApp extends StatefulWidget {
  @override
  _BarcodeScannerAppState createState() => _BarcodeScannerAppState();
}

class _BarcodeScannerAppState extends State<BarcodeScannerApp> {
  TextEditingController _serialNumberController = TextEditingController();
  TextEditingController _tagNumberController = TextEditingController();
  String? serialNumber;
  String? tagNumber;
  String? selectedScanner = 'Phone Camera'; // Default option for scanning
  bool isOTGDeviceConnected = false;

  // Default values for user, location, and asset description
  String? defaultUser;
  String? defaultLocation;
  String? defaultAssetDescription;

  @override
  void initState() {
    super.initState();
    _checkOTGConnection();
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _tagNumberController.dispose();
    super.dispose();
  }

  void _checkOTGConnection() async {
    List devices = await UsbSerial.listDevices();
    setState(() {
      isOTGDeviceConnected = devices.isNotEmpty;
    });
  }

  Future<String?> _scanBarcodeUsingCamera() async {
    try {
      var result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void _processScannedData() {
    // Check if we already have a similar entry
    if (_isSimilarDataExists()) {
      // If similar data exists, prompt to scan only tag and serial number
      _promptForSimilarData();
    } else {
      // Show confirmation dialog with the scanned details
      _showConfirmationDialog();
    }
  }

  bool _isSimilarDataExists() {
    // Logic to check if similar data already exists (you may want to replace this with actual logic)
    return false; // This should be replaced with actual comparison logic.
  }

  void _promptForSimilarData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Similar Data'),
          content: Text('Please scan the Serial Number and Tag Number.'),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _scanForSimilarData();
              },
            ),
          ],
        );
      },
    );
  }

  void _scanForSimilarData() async {
    // Scan Serial Number
    String? scannedSerial = await _scanBarcodeUsingCamera();
    if (scannedSerial != null) {
      setState(() {
        serialNumber = scannedSerial;
      });
    }

    // Scan Tag Number
    String? scannedTag = await _scanBarcodeUsingCamera();
    if (scannedTag != null) {
      setState(() {
        tagNumber = scannedTag;
      });
      // Automatically set user, location, and asset description to defaults
      _uploadScannedData(defaultUser, defaultLocation, defaultAssetDescription);
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Scanned Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Serial Number: $serialNumber'),
              Text('Tag Number: $tagNumber'),
              Text('User: ${defaultUser ?? 'N/A'}'),
              Text('Location: ${defaultLocation ?? 'N/A'}'),
              Text('Date: ${DateTime.now()}'),
              Text('Asset Description: ${defaultAssetDescription ?? 'N/A'}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Edit"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                Navigator.of(context).pop();
                _uploadScannedData(defaultUser, defaultLocation, defaultAssetDescription);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadScannedData(String? user, String? location, String? assetDescription) async {
    // Example code to upload data, replace with your upload logic
    final dataToUpload = {
      'serial_number': serialNumber,
      'tag_number': tagNumber,
      'location': location ?? 'Default Location', // Use default location if not provided
      'date': DateTime.now().toIso8601String(),
      'user': user ?? 'Default User', // Use default user if not provided
      'asset_description': assetDescription ?? 'Default Description' // Use default description if not provided
    };

    // Simulate a successful upload with a delay
    await Future.delayed(Duration(seconds: 2));

    // Show a success message after uploading
    _showSuccessDialog('Upload Successful', 'The scanned data has been uploaded successfully.');
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                // Reset fields after successful upload
                setState(() {
                  serialNumber = null;
                  tagNumber = null;
                  _serialNumberController.clear();
                  _tagNumberController.clear();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startScanning() async {
    if (selectedScanner == 'Phone Camera') {
      // Using phone camera
      String? scannedData = await _scanBarcodeUsingCamera();
      setState(() {
        serialNumber = scannedData;
      });
    } else if (selectedScanner == 'OTG Device') {
      // Using OTG device (data would be automatically inputted into the TextField)
      // Implement your logic for scanning with OTG here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcodes')),
      body: SingleChildScrollView(  // <-- Wrap with SingleChildScrollView for scrolling
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dropdown to select scanning method
              Row(
                children: [
                  Text("Select Scanner: "),
                  DropdownButton<String>(
                    value: selectedScanner,
                    items: [
                      DropdownMenuItem(
                        child: Text('Phone Camera'),
                        value: 'Phone Camera',
                      ),
                      DropdownMenuItem(
                        child: Text('OTG Device'),
                        value: 'OTG Device',
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedScanner = value!;
                        _checkOTGConnection();
                      });
                    },
                  ),
                  // Show OTG connection status
                  if (selectedScanner == 'OTG Device')
                    Text(isOTGDeviceConnected ? " (Connected)" : " (Not Connected)",
                        style: TextStyle(
                            color: isOTGDeviceConnected ? Colors.green : Colors.red)),
                ],
              ),
              SizedBox(height: 20),

              // Button to start scanning based on selected option
              ElevatedButton(
                onPressed: () {
                  _startScanning();
                },
                child: Text('Start Scanning'),
              ),
              SizedBox(height: 20),

              // Serial Number input field (will capture barcode input from the reader)
              TextField(
                controller: _serialNumberController,
                decoration: InputDecoration(
                  labelText: 'Serial Number',
                ),
                onChanged: (value) {
                  setState(() {
                    serialNumber = value;
                  });
                },
              ),
              SizedBox(height: 20),

              // Tag Number input field (will capture barcode input from the reader)
              TextField(
                controller: _tagNumberController,
                decoration: InputDecoration(
                  labelText: 'Tag Number',
                ),
                onSubmitted: (value) {
                  setState(() {
                    tagNumber = value;
                  });
                  _processScannedData();
                },
              ),
              SizedBox(height: 20),

              // User input field (for first-time setup)
              TextField(
                decoration: InputDecoration(
                  labelText: 'User',
                ),
                onChanged: (value) {
                  defaultUser = value; // Store default user
                },
              ),
              SizedBox(height: 20),

              // Location input field (for first-time setup)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Location',
                ),
                onChanged: (value) {
                  defaultLocation = value; // Store default location
                },
              ),
              SizedBox(height: 20),

              // Asset Description input field (for first-time setup)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Asset Description',
                ),
                onChanged: (value) {
                  defaultAssetDescription = value; // Store default description
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
