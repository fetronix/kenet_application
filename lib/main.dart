import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/login_bloc.dart';
import 'blocs/register_bloc.dart';
import 'blocs/home_bloc.dart';
import 'blocs/consignments_bloc.dart';
import 'blocs/assets_bloc.dart';
import 'blocs/receivings_bloc.dart';
import 'blocs/dispatch_cart_bloc.dart';
import 'blocs/applications_bloc.dart';
import 'blocs/settings_bloc.dart';
import 'blocs/about_bloc.dart';
import 'screens/walkthrough_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/consignments_screen.dart'; // Import the consignments screen
import 'screens/dispatch_cart_screen.dart'; // Import the dispatch screen
import 'screens/applications_screen.dart'; // Import the applications screen
import 'screens/receivings_screen.dart'; // Import the receivings screen
import 'screens/about_screen.dart'; // Import the receivings screen
import 'screens/settings_screen.dart'; // Import the receivings screen
import 'screens/assets_screen.dart'; // Import the receivings screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider<RegisterBloc>(
          create: (context) => RegisterBloc(),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
        ),
        BlocProvider<ConsignmentsBloc>(
          create: (context) => ConsignmentsBloc(),
        ),
        BlocProvider<ReceivingsBloc>(
          create: (context) => ReceivingsBloc(),
        ),BlocProvider<DispatchCartBloc>(
          create: (context) => DispatchCartBloc(),
        ),BlocProvider<ApplicationsBloc>(
          create: (context) => ApplicationsBloc(),
        ),BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),BlocProvider<AboutBloc>(
          create: (context) => AboutBloc(),
        ),BlocProvider<AssetsBloc>(
          create: (context) => AssetsBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'K.M.A.S',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: WalkthroughScreen(), // Initial screen
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/about': (context) => AboutScreen(),
          '/settings': (context) => SettingsScreen(),
          '/home': (context) => HomeScreen(), // HomeScreen route
          '/consignments': (context) => ConsignmentsScreen(), // Consignments route
          '/dispatch-cart': (context) => DispatchCartScreen(), // Dispatch route
          '/applications': (context) => ApplicationsScreen(), // Applications route
          '/receivings': (context) => ReceivingsScreen(), // Receivings route
          '/assets': (context) => AssetsScreen(), // Receivings route
        },
      ),
    );
  }
}
