import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/assets_bloc.dart'; // Import the AssetsBloc

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assets'),
      ),
      body: BlocBuilder<AssetsBloc, AssetsState>(
        builder: (context, state) {
          if (state is AssetsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is AssetsLoaded) {
            return ListView.builder(
              itemCount: state.assets.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.assets[index]),
                );
              },
            );
          } else if (state is AssetsError) {
            return Center(child: Text('Failed to load assets'));
          }
          return Center(child: Text('No assets available'));
        },
      ),
    );
  }
}
