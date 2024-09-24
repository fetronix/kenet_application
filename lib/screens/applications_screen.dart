import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/applications_bloc.dart'; // Import the ApplicationsBloc

class ApplicationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applications'),
      ),
      body: BlocBuilder<ApplicationsBloc, ApplicationsState>(
        builder: (context, state) {
          if (state is ApplicationsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is ApplicationsLoaded) {
            return ListView.builder(
              itemCount: state.applications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.applications[index]),
                );
              },
            );
          } else if (state is ApplicationsError) {
            return Center(child: Text('Failed to load applications'));
          }
          return Center(child: Text('No applications available'));
        },
      ),
    );
  }
}
