import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kenet_application/blocs/kenet_colors.dart';
import '../blocs/dispatch_cart_bloc.dart'; // Import your DispatchCartBloc
import '../blocs/dispatch_cart_item.dart'; // Import your DispatchCartItem model

class DispatchCartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispatch Cart'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              // Clear the dispatch cart when the button is pressed
              BlocProvider.of<DispatchCartBloc>(context).add(ClearDispatchCartEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<DispatchCartBloc, DispatchCartState>(
        builder: (context, state) {
          if (state is DispatchCartLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is DispatchCartLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No items in dispatch portal'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the homepage
                        Navigator.pop(context); // Adjust this to your homepage route
                      },
                      child: Text('Go to Homepage', style: TextStyle(color: Colors.white, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KenetColors.primaryColor, // Customize button color
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asset Name: ${item.assetName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Serial Number: ${item.serialNumber}'),
                              Text('Tag Number: ${item.tagNumber}'),
                              Text('Location: ${item.location}'),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.delete, color: Colors.white),
                                    label: Text('Remove', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KenetColors.accentColor,
                                    ),
                                    onPressed: () {
                                      // Remove the item from the dispatch cart when the button is pressed
                                      BlocProvider.of<DispatchCartBloc>(context)
                                          .add(RemoveItemFromDispatchCartEvent(item));
                                    },
                                  ),
                                  Text(
                                    'Received By: ${item.receivedName ?? 'N/A'}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the checkout page
                      Navigator.of(context).pushNamed('/checkout'); // Adjust this to your checkout route
                    },
                    child: Text('Proceed to Checkout', style: TextStyle(fontSize: 15,color: KenetColors.backgroundColor,)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KenetColors.primaryColor, // Customize button color
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is DispatchCartError) {
            return Center(
              child: Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "There are duplicate assets added to your dispatch..... '\nKindly clear the cart and add only 1 item.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: KenetColors.primaryColor, // Optional: Change text color to indicate error
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
              ),
            );
          }
          return Container(); // Default case
        },
      ),
    );
  }
}
