import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String accessToken;
  final String refreshToken;

  const AdminScreen({
    Key? key,
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'), // AppBar title
        backgroundColor: Color(0xFF9C27B0), // Accent color for the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $firstName $lastName', // Display welcome message
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your Email: $email', // Display user email
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your action for this button
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9C27B0), // Accent color for the button
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Manage Users'), // Button to manage users
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add your action for this button
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9C27B0), // Accent color for the button
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('View Reports'), // Button to view reports
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add your action for this button
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9C27B0), // Accent color for the button
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Settings'), // Button for settings
            ),
          ],
        ),
      ),
    );
  }
}
