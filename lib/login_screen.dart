import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenet_application/shared_pref_helper.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';  // Make sure to create this file
import 'dart:developer'; // For logging

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    // Define your login API URL
    const url = 'http://197.136.16.164:8000/app/api/login/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
        }),
      );

      // Log the response status and body
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log the access and refresh tokens
        log('Access Token: ${data['access']}');
        log('Refresh Token: ${data['refresh']}');

        // Store tokens and user data using SharedPrefHelper
        SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
        await sharedPrefHelper.saveAccessToken(data['access']);
        await sharedPrefHelper.saveRefreshToken(data['refresh']);
        await sharedPrefHelper.saveUserInfo(
          data['user']['id'].toString(),  // Save user ID
          data['user']['username'],
          data['user']['first_name'],
          data['user']['last_name'],
          data['user']['email'],
          data['user']['role'],
          data['access'],  // Save access token as part of user info
          data['refresh'],  // Save refresh token as part of user info
        );

        // Log that user info has been saved
        log('User info saved successfully: ${data['user']['id']}, ${data['user']['username']}, ${data['user']['first_name']}, ${data['user']['last_name']}, ${data['user']['email']}, ${data['user']['role']}');

        // Navigate to HomeScreen with user details
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              id: data['user']['id'].toString(),
              username: data['user']['username'],
              firstName: data['user']['first_name'],
              lastName: data['user']['last_name'],
              email: data['user']['email'],
              role: data['user']['role'],
              accessToken: data['access'],
              refreshToken: data['refresh'],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      }
    } catch (e) {
      log('Error during login: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                onChanged: (value) {
                  _username = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) {
                  _password = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 20),
              ],
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _login();
                  }
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
