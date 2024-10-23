import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';



class ReleaseForm extends StatelessWidget {

  final Map<String, dynamic> asset; // Declare the asset field

  // Constructor to accept the asset parameter
  ReleaseForm({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KENET Release Form',
      home: Scaffold(
        appBar: AppBar(
          title: Text("KENET Release Form"),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/logo.png', // Update with your logo path
                width: 50,
                height: 50,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: FormLayout(asset:asset),
        ),
      ),
    );
  }
}

class FormLayout extends StatefulWidget {
  final Map<String, dynamic> asset; // Declare the asset field

  // Constructor to accept the asset parameter
  FormLayout({Key? key, required this.asset}) : super(key: key);

  @override
  _FormLayoutState createState() => _FormLayoutState();
}

class _FormLayoutState extends State<FormLayout> {
  late SignatureController _signatureController;
  late SignatureController _AsignatureController;

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _AnameController;
  late TextEditingController _dateController;
  late TextEditingController _currentLocationController;
  late TextEditingController _newLocationController;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityRequiredController = TextEditingController();
  final TextEditingController _quantityIssuedController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _kenetTagNumberController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
    );
    _AsignatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
    );

    // Initialize controllers
    _nameController = TextEditingController();
    _AnameController = TextEditingController();
    _dateController = TextEditingController();
    // Set current date in the required format
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateController = TextEditingController(text: formattedDate); // Set the current date
    _currentLocationController = TextEditingController(text: "KENET Office");
    _newLocationController = TextEditingController();


  }

  void _saveSignature() async {
    final Uint8List? data = await _signatureController.toPngBytes();
    if (data != null) {
      // Handle the signature data, e.g., save or upload it.
      print('Signature data length: ${data.length}');
      // You can save or upload the signature image here.
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    _AnameController.dispose();
    _dateController.dispose();
    _currentLocationController.dispose();
    _newLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderSection(),
          _buildInstructionsSection(),
          _buildFieldsSection(),
          _buildPropertyDescriptionTable(),
          _buildSignatureSection(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // Use Expanded to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EQUIPMENT RELEASE FORM FOR KENET",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 60,
              ),
              SizedBox(height: 10),
              Text("KENET SECRETARIAT"),
              Text("P.O BOX 30244 00100, NAIROBI."),
              Text("E-mail: info@kenet.or.ke"),
              Text("Tel: 0732 150000 / 0703 044500"),
              SizedBox(height: 20),
            ],
          ),
        ),

      ],
    );
  }


  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "INSTRUCTIONS:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("1) Complete boxes 1 through to 3."),
        Text("2) Enter the description and quantity only under Property description."),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFieldsSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Container(
        width: 700, // Use full width of the screen
        child: Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: {
            0: FlexColumnWidth(1), // Adjust width as necessary
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1), // Add width for the signature column
          },
          children: [
            // Header Row
            TableRow(children: [
              _buildTableHeaderCell("1\nName & Date:"),
              _buildTableHeaderCell("2\nOrganization:"),
              _buildTableHeaderCell("3\nLocation:"),
              _buildTableHeaderCell("4\nSignature:"), // Header for Signature
            ]),
            // Data Row
            TableRow(children: [
              _buildTableCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Name",
                    ),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Date",
                    ),
                  ),
                ],
              )),
              _buildTableCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                  children: [
                    Text("KENET", style: TextStyle(fontWeight: FontWeight.bold)), // Make it bold
                    SizedBox(height: 5),
                    // Removed the TextFormField for Signature
                    // Signature Pad will be added in the next column
                  ],
                ),
              ),
              _buildTableCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                children: [
                  TextFormField(
                    controller: _currentLocationController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Current Location",
                    ),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _newLocationController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "New Location",
                    ),
                  ),
                ],
              )),
              _buildTableCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                  children: [
                    // Add the signature pad here
                    Container(
                      height: 100, // Set a fixed height for the signature pad
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black), // Add border to signature pad
                      ),
                      child: Signature(
                        controller: _signatureController, // Use your signature controller
                        height: 100,
                        backgroundColor: Colors.transparent, // Set background color
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }


  Widget _buildPropertyDescriptionTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to start
        children: [
          Text(
            "Property Description", // Title text
            style: TextStyle(
              fontSize: 20, // Title font size
              fontWeight: FontWeight.bold, // Make the title bold
            ),
          ),
          SizedBox(height: 10), // Add some space between the title and the table
          Container(
            width: 1000, // Use full width of the screen
            child: Table(
              border: TableBorder.all(color: Colors.black, width: 1), // Outer border
              columnWidths: {
                0: FlexColumnWidth(2), // Description column
                1: FlexColumnWidth(1), // Quantity Required column
                2: FlexColumnWidth(1), // Quantity Issued column
                3: FlexColumnWidth(1), // Serial Number column
                4: FlexColumnWidth(1), // KENET Tag Number column
              },
              children: [
                // Header Row
                TableRow(children: [
                  _buildTableHeaderCell("Description"),
                  _buildTableHeaderCell("Quantity Required"),
                  _buildTableHeaderCell("Quantity Issued"),
                  _buildTableHeaderCell("Serial Number"),
                  _buildTableHeaderCell("KENET Tag Number"),
                ]),
                // Data Rows
                TableRow(children: [
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      Text(widget.asset["asset_description"] ?? "No Description"), // Use asset description
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      TextField(controller: _quantityRequiredController), // Quantity required input
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      TextField(controller: _quantityIssuedController), // Quantity issued input
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      Text(widget.asset["serial_number"] ?? "N/A"), // Serial Number
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      Text(widget.asset["kenet_tag"] ?? "N/A"), // KENET Tag Number
                    ],
                  )),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper methods for creating table cells
  Widget _buildTableHeaderCell(String title) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: child,
    );
  }




  Widget _buildSignatureSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to start
        children: [
          Text(
            "Authorizing Signature", // Title text
            style: TextStyle(
              fontSize: 20, // Title font size
              fontWeight: FontWeight.bold, // Make the title bold
            ),
          ),
          SizedBox(height: 10), // Add some space between the title and the table
          Container(
            width: 700, // Use full width of the screen
            child: Table(
              border: TableBorder.all(color: Colors.black, width: 1), // Outer border
              columnWidths: {
                0: FlexColumnWidth(2), // Name column
                1: FlexColumnWidth(2), // Signature column
                2: FlexColumnWidth(1), // Date column
              },
              children: [
                // Header Row
                TableRow(children: [
                  _buildTableHeaderCell("Name"),
                  _buildTableHeaderCell("Signature"),
                  _buildTableHeaderCell("Date"),
                ]),
                // Data Row
                TableRow(children: [
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      TextFormField(
                        controller: _AnameController, // New controller for name
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Name",
                        ),
                      ),
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      // Signature Pad
                      Container(
                        height: 100, // Set a fixed height for the signature pad
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black), // Add border to signature pad
                        ),
                        child: Signature(
                          controller: _AsignatureController, // Use your signature controller
                          height: 100,
                          backgroundColor: Colors.transparent, // Set background color
                        ),
                      ),
                    ],
                  )),
                  _buildTableCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      TextFormField(
                        controller: _dateController, // New controller for date
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Date",
                        ),
                      ),
                    ],
                  )),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text("Version 1.0.0   Reference: KS/ERF"),
          SizedBox(height: 20),
          Image.asset(
            'assets/images/kenet_stamp.png',
            width: 300,
            height: 200,
          ),
          SizedBox(height: 20), // Add space between the logo and the button
          ElevatedButton(
            onPressed: () {
              // Add your button action here
              print("Button Pressed!"); // Example action
            },
            child: Text("Submit"), // Button text
          ),
        ],
      ),
    );
  }




}
