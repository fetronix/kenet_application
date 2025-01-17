import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KENET Assets',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Directly navigate to the LoginScreen
      routes: {
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

class VersionCheckScreen extends StatelessWidget {
  const VersionCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome to KENET Assets")),
      body: Center(
        child: Text(
          'No version check in this build.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
