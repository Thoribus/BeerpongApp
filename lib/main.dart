import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:beerpongapp/screens/base_screen.dart'; // Import your BaseScreen class
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/screens/home_screen.dart';

// The main function is the entry point of the Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that the Flutter binding is initialized.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Run the app and pass an instance of MyApp to it.
}

// MyApp is a stateless widget that represents the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // The build method describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beerpong Compagnion!',
      theme: ThemeData(
        primarySwatch: Colors.amber, // Adjust the theme as per your design
      ),
      initialRoute: '/', // Set initial route
      routes: {
        '/': (context) => BaseScreen(
            child: HomeScreen(), selectedIndex: 2), // Example initial screen
        '/friendlist': (context) =>
            BaseScreen(child: FriendsListScreen(), selectedIndex: 1),
        '/statistics': (context) =>
            BaseScreen(child: StatisticsScreen(), selectedIndex: 3),
        '/account': (context) =>
            BaseScreen(child: AccountScreen(), selectedIndex: 4),
        // Add routes for all screens you want to navigate to
      },
    );
  }
}
