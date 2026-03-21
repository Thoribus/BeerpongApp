import 'dart:async';

import 'package:beerpongapp/services/ad_service.dart';
import 'package:beerpongapp/services/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/util/theme_provider.dart';
import 'package:beerpongapp/util/router.dart';
import 'package:beerpongapp/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await MobileAds.instance.initialize();
  unawaited(AdService.instance.preload());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initLocalNotifications();

  // Create UserProvider before runApp so the router can reference it as
  // a refreshListenable for the auth redirect guard.
  final userProvider = UserProvider();
  unawaited(userProvider.loadUser());

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://d8383eb3dbe512aff8d55ff5335b2f87@o4511078596870144.ingest.de.sentry.io/4511078600147024';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: 
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(userProvider: userProvider),
    ),
  )),
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

