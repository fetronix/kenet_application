import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static final SharedPrefHelper _instance = SharedPrefHelper._internal();

  factory SharedPrefHelper() {
    return _instance;
  }

  SharedPrefHelper._internal();

  // Initialize SharedPreferences
  Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  // Save access token
  Future<void> saveAccessToken(String token) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString('access_token', token);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString('refresh_token', token);
  }

  // Save user information including user ID
  Future<void> saveUserInfo(String id, String username, String firstName, String lastName, String email, String role, String accessToken, String refreshToken) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString('id', id);  // Save user ID
    await prefs.setString('username', username);
    await prefs.setString('first_name', firstName);
    await prefs.setString('last_name', lastName);
    await prefs.setString('email', email);
    await prefs.setString('role', role);
    await prefs.setString('access_token', accessToken); // Save access token
    await prefs.setString('refresh_token', refreshToken); // Save refresh token
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString('access_token');
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString('refresh_token');
  }

  // Get user information
  Future<Map<String, String?>> getUserInfo() async {
    final SharedPreferences prefs = await _prefs();
    return {
      'id': prefs.getString('id'), // Get user ID
      'username': prefs.getString('username'),
      'first_name': prefs.getString('first_name'),
      'last_name': prefs.getString('last_name'),
      'email': prefs.getString('email'),
      'role': prefs.getString('role'),
      'access_token': prefs.getString('access_token'), // Get access token
      'refresh_token': prefs.getString('refresh_token'), // Get refresh token
    };
  }

  // Get user ID
  Future<String?> getUserId() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString('id'); // Retrieve the user ID
  }

  // Clear all user data (used for logout)
  Future<void> clearAllData() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.clear();
  }
}
