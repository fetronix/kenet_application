import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kenet_application/shared_pref_helper.dart';
import 'package:kenet_application/allUrls.dart';
import 'package:kenet_application/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
    _checkLoginStatus();
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

  void _checkLoginStatus() async {
    try {
      SharedPrefHelper sharedPrefHelper = SharedPrefHelper();

      // Get tokens from shared preferences
      String? accessToken = await sharedPrefHelper.getAccessToken();
      String? refreshToken = await sharedPrefHelper.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        // Get user details from shared preferences
        String? id = await sharedPrefHelper.getUserId();
        Map<String, String?> userInfo = await sharedPrefHelper.getUserInfo();



        // Ensure all required details are present
        if (id != null &&
            userInfo['username'] != null &&
            userInfo['first_name'] != null &&
            userInfo['last_name'] != null &&
            userInfo['email'] != null &&
            userInfo['role'] != null) {
          // Navigate to HomeScreen with user details
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                id: id,
                username: userInfo['username']!,
                firstName: userInfo['first_name']!,
                lastName: userInfo['last_name']!,
                email: userInfo['email']!,
                accessToken: accessToken,
                refreshToken: refreshToken,
                role: userInfo['role']!,
              ),
            ),
          );
        } else {
          log('Incomplete user information in shared preferences');
        }
      }
    } catch (e) {
      log('Error checking login status: $e');
    }
  }




  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  void _launchForgotPasswordURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Handles the login process
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    const url = ApiUrls.login;

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

        String role = data['user']['role'];

        if (role == 'can_view' || role == 'can_checkout_items') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                id: data['user']['id'].toString(),
                username: data['user']['username'],
                firstName: data['user']['first_name'],
                lastName: data['user']['last_name'],
                email: data['user']['email'],
                accessToken: data['access'],
                refreshToken: data['refresh'],
                role: role,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Access denied for your role';
          });
        }
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
              Color(0xFF00BCD4),
              Color(0xFF673AB7),
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
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          labelText: 'Kenet Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Kenet username';
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
                              backgroundColor: Color(0xFF9C27B0),
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
                      GestureDetector(
                        onTap: () {
                          // Replace this with your password reset URL or navigation to password reset screen
                          const url = ApiUrls.passwordReset; // Update with actual URL
                          _launchForgotPasswordURL(url);
                        },
                        child: Center(  // Wrap the Text widget with a Center widget
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
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

  const BLinkingLight({super.key, required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: CircleAvatar(
        radius: 8,
        backgroundColor: color,
      ),
    );
  }
}
