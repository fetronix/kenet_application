import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/home_bloc.dart';
import '../blocs/dispatch_cart_bloc.dart'; // Import DispatchCartBloc
import '../blocs/kenet_colors.dart';
import '../blocs/dispatch_cart_item.dart'; // Import DispatchCartItem model

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _itemsPerPage = 10; // Number of items per page

  @override
  void initState() {
    super.initState();
    // Dispatch event to load initial data
    BlocProvider.of<HomeBloc>(context).add(LoadHomeDataEvent());
  }

  List<dynamic> _getCurrentPageItems(List<dynamic> items) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return items.sublist(startIndex, endIndex > items.length ? items.length : endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('K.M.A.S'),
        actions: [
          BlocBuilder<DispatchCartBloc, DispatchCartState>(
            builder: (context, state) {
              int dispatchCount = 0;
              if (state is DispatchCartLoaded) {
                dispatchCount = state.items.length;
              }

              return IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.local_shipping),
                    if (dispatchCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: KenetColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$dispatchCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/dispatch-cart'); // Navigate to the dispatch list
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.purple[50],
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                SizedBox(height: 10),
                _buildCategoriesTitle(),
                _buildCategoryButtons(),
                SizedBox(height: 10),
                _buildDataTable(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                height: 100,
              ),
            ),
            decoration: BoxDecoration(color: KenetColors.primaryColor),
          ),
          _buildDrawerButton(context, Icons.home, 'Home', '/home'),
          _buildDrawerButton(context, Icons.settings, 'Settings', '/settings'),
          _buildDrawerButton(context, Icons.assignment, 'Consignments', '/consignments'),
          _buildDrawerButton(context, Icons.local_shipping, 'Dispatch List', '/dispatch-cart'),
          _buildDrawerButton(context, Icons.apps, 'Applications', '/applications'),
          _buildDrawerButton(context, Icons.archive, 'Receivings', '/receivings'),
          _buildDrawerButton(context, Icons.inventory, 'Assets', '/assets'),
          _buildDrawerButton(context, Icons.info, 'About', '/about'),
          _buildDrawerButton(context, Icons.exit_to_app, 'Logout', '/logout'),
        ],
      ),
    );
  }

  Widget _buildDrawerButton(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KenetColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () {
          if (route == '/logout') {
            _logout(context);
          } else {
            Navigator.of(context).pushNamed(route);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Text(title, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    // Clear any user-related data or tokens if needed.
    // Navigate to the login screen
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: KenetColors.primaryColor),
                ),
                filled: true,
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<HomeBloc>(context).add(SearchHomeEvent(query: _searchController.text));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KenetColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.white),
                SizedBox(width: 5),
                Text('Search', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTitle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Categories',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is HomeLoaded) {
          // Extracting unique categories
          final categories = state.items
              .map((item) => item["category"])
              .toSet()
              .toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Use named parameters when creating the event
                      BlocProvider.of<HomeBloc>(context).add(FilterByCategoryEvent(category: category));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: KenetColors.primaryColor),
                    child: Text(
                      category,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildDataTable() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is HomeLoaded) {
          final items = state.items;
          final currentPageItems = _getCurrentPageItems(items);

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Tag Number')),
                    // DataColumn(label: Text('Serial Number')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Dispatch')),
                  ],
                  rows: currentPageItems.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item["asset_name"])),
                      DataCell(Text(item["tag_number"])),
                      // DataCell(Text(item["serial_number"])),
                      DataCell(Text(item["status"])),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.add),
                          color: KenetColors.primaryColor,
                          onPressed: () {
                            _showDispatchModal(context, item);  // Show modal with item details
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              _buildPagination(items.length),
            ],
          );
        }
        return Container();
      },
    );
  }

  void _showDispatchModal(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dispatch Asset Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asset Name: ${item["asset_name"]}'),
              Text('Tag Number: ${item["tag_number"]}'),
              Text('Serial Number: ${item["serial_number"]}'),
              Text('Location: ${item["location_name"]}'),
              Text('Received By: ${item["received_by_name"]}'),
              Text('Project: ${item["project"]}'),
              Text('Comments: ${item["comments"]}'),
              Text('Invoice number: ${item["invoice_number"]}'),
              Text('Category: ${item["category"]}'),
              Text('Supplier: ${item["supplier"]}'),
              Text('Status: ${item["status"]}'),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: KenetColors.accentColor),
                    child: Text('Cancel',style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      DispatchCartItem dispatchCartItem = DispatchCartItem(
                        tagNumber: item["tag_number"],
                        serialNumber: item["serial_number"],
                        location: item["location_name"],
                        assetName: item["asset_name"],
                        receivedName: item["received_by_name"],
                      );
                      BlocProvider.of<DispatchCartBloc>(context)
                          .add(AddItemToDispatchCartEvent(dispatchCartItem));
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: KenetColors.secondaryColor),
                    child: Text('Add to Dispatch List',style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Implement your "Dispatch Now" logic here
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: KenetColors.primaryColor),
                    child: Text('Dispatch Now',style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentPage = index; // Update current page
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage == index ? KenetColors.primaryColor : Colors.grey,
            ),
            child: Text((index + 1).toString(), style: TextStyle(color: Colors.white)),
          ),
        );
      }),
    );
  }
}
