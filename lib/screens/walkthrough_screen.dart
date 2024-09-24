import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart'; // Import the login_screen.dart file
import '../blocs/login_bloc.dart'; // Import the login_bloc.dart file

// Define Kenet Colors
class KenetColors {
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep purple
  static const Color secondaryColor = Color(0xFF24751F); // Teal
  static const Color accentColor = Color(0xFF8C0B0B); // Amber
  static const Color backgroundColor = Color(0xFFFFFFFF); // Light purple background
}

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  _WalkthroughScreenState createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          _buildPage(
              context,
              'Welcome to the App',
              'This is the first screen of the walkthrough',
              KenetColors.primaryColor,
              Icons.explore),
          _buildPage(
              context,
              'Discover Features',
              'Here are some of the key features of our app',
              KenetColors.secondaryColor,
              Icons.featured_play_list),
          _buildLastPage(context),
        ],
      ),
      bottomNavigationBar: _buildIndicator(),
    );
  }

  Widget _buildPage(BuildContext context, String title, String description,
      Color color, IconData icon) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.white),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastPage(BuildContext context) {
    return Container(
      color: KenetColors.accentColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.done, size: 100, color: Colors.white),
          const SizedBox(height: 40),
          const Text(
            'Let\'s Get Started!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'This is the last screen of the walkthrough.',
            style: TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to LoginScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KenetColors.primaryColor, // Button background color
              foregroundColor: Colors.white, // Button text color
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text(
              'Finish Walkthrough',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: _currentPage == index ? 12.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? KenetColors.primaryColor
                : Colors.grey,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}
