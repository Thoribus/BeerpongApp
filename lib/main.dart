import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/screens/base_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that the Flutter binding is initialized.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider()..loadUser(),
      child: const MyApp(),
    ),
  );
}

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
        '/': (context) =>
            const BaseScreen(selectedIndex: 2), // Example initial screen
        '/friendlist': (context) => const BaseScreen(selectedIndex: 1),
        '/statistics': (context) => const BaseScreen(selectedIndex: 3),
        '/account': (context) => const BaseScreen(selectedIndex: 4),
        // Add routes for all screens you want to navigate to
      },
    );
  }
}
