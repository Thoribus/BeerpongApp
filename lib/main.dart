import 'dart:async';

import 'package:beerpongapp/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/util/theme_provider.dart';
import 'package:beerpongapp/util/router.dart';
import 'package:beerpongapp/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initLocalNotifications();

  // Create UserProvider before runApp so the router can reference it as
  // a refreshListenable for the auth redirect guard.
  final userProvider = UserProvider();
  unawaited(userProvider.loadUser());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(userProvider: userProvider),
    ),
  );
}

class MyApp extends StatefulWidget {
  final UserProvider userProvider;
  const MyApp({super.key, required this.userProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Created once; holds a reference to userProvider for auth redirects.
  late final _router = AppRouter.createRouter(widget.userProvider);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'Beerpong Companion',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}

