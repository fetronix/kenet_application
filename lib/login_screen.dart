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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    const url = 'http://197.136.16.164:8000/app/api/login/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        SharedPrefHelper sharedPrefHelper = SharedPrefHelper();
        await sharedPrefHelper.saveAccessToken(data['access']);
        await sharedPrefHelper.saveRefreshToken(data['refresh']);
        await sharedPrefHelper.saveUserInfo(
          data['user']['id'].toString(),
          data['user']['username'],
          data['user']['first_name'],
          data['user']['last_name'],
          data['user']['email'],
          data['user']['role'],
          data['access'],
          data['refresh'],
        );

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00BCD4), // Primary color
              Color(0xFF673AB7), // Secondary color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png', // Update with your image path
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Blinking lights above the "Welcome Back" text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BLinkingLight(animation: _animation, color: Colors.red),
                          const SizedBox(width: 10),
                          BLinkingLight(animation: _animation, color: Colors.green),
                          const SizedBox(width: 10),
                          BLinkingLight(animation: _animation, color: Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: Offset(1, 1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'kenet email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your kenet email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF9C27B0), // Accent color
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BLinkingLight extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const BLinkingLight({Key? key, required this.animation, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
