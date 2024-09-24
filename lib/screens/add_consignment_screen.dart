import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/add_consignment_bloc.dart'; // Import the AddConsignmentBloc

class AddConsignmentScreen extends StatelessWidget {
  final TextEditingController _slkIdController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Consignment'),
      ),
      body: BlocListener<AddConsignmentBloc, AddConsignmentState>(
        listener: (context, state) {
          if (state is AddConsignmentSuccess) {
            Navigator.pop(context); // Go back after successful submission
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Consignment added successfully!')));
          } else if (state is AddConsignmentError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add consignment!')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _slkIdController,
                decoration: InputDecoration(labelText: 'SLK ID'),
              ),
              TextField(
                controller: _supplierController,
                decoration: InputDecoration(labelText: 'Supplier'),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final slkId = _slkIdController.text;
                  final supplier = _supplierController.text;
                  final quantity = int.tryParse(_quantityController.text) ?? 0;

                  // Trigger the submission event
                  BlocProvider.of<AddConsignmentBloc>(context).add(SubmitConsignmentEvent(
                    slkId: slkId,
                    supplier: supplier,
                    quantity: quantity,
                  ));
                },
                child: Text('Add Consignment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
