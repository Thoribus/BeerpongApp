import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // Import the home screen from the screens directory

// The main function is the entry point of the Flutter application.
void main() {
  runApp(const MyApp()); // Run the app and pass an instance of MyApp to it.
}

// MyApp is a stateless widget that represents the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // The build method describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beerpong App', // The title of the application
      theme: ThemeData(
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.white, // Default button colorr
          textTheme: ButtonTextTheme.primary, // Default button text theme
        ),
        useMaterial3: true, // Use Material Design 3
      ),
      home: const HomeScreen(), // Set HomeScreen as the initial route
    );
  }
}
