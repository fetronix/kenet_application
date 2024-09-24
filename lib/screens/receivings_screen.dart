import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/receivings_bloc.dart'; // Import the ReceivingsBloc

class ReceivingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receivings'),
      ),
      body: BlocBuilder<ReceivingsBloc, ReceivingsState>(
        builder: (context, state) {
          if (state is ReceivingsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is ReceivingsLoaded) {
            return ListView.builder(
              itemCount: state.receivings.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.receivings[index]),
                );
              },
            );
          } else if (state is ReceivingsError) {
            return Center(child: Text('Failed to load receivings'));
          }
          return Center(child: Text('No receivings available'));
        },
      ),
    );
  }
}
