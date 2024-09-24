import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/consignments_bloc.dart'; // Import the ConsignmentsBloc
import '../blocs/add_consignment_bloc.dart'; // Import the AddConsignmentBloc
import 'add_consignment_screen.dart'; // Import the AddConsignmentScreen

class ConsignmentsScreen extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // Add some padding for the add button
              child: IconButton(
                icon: Icon(Icons.add, size: 30), // Increase the size of the add icon
                onPressed: () {
                  // Navigate to the AddConsignmentScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => AddConsignmentBloc(),
                        child: AddConsignmentScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search consignments...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min, // Ensures the row takes minimum space
                      children: [
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            print('Searching for: ${_searchController.text}'); // Placeholder for search functionality
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear(); // Clear the search field
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Consignments',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
