import 'dart:async';

import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:beerpongapp/services/ad_service.dart';
import 'package:beerpongapp/services/notification_service.dart';
import 'package:beerpongapp/services/purchase_service.dart';
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

  // On iOS 14+, request ATT permission before initialising ads so AdMob can
  // serve personalised ads. On Android this is a no-op.
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // Brief delay recommended by Apple to avoid showing the prompt before
      // the app's first frame is visible.
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  await MobileAds.instance.initialize();
  unawaited(AdService.instance.preload());
  unawaited(PurchaseService.instance.initialize());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initLocalNotifications();

  // Create UserProvider before runApp so the router can reference it as
  // a refreshListenable for the auth redirect guard.
  final userProvider = UserProvider();
  unawaited(userProvider.loadUser());

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://d8383eb3dbe512aff8d55ff5335b2f87@o4511078596870144.ingest.de.sentry.io/4511078600147024';
      options.sendDefaultPii = true;
      options.enableLogs = true;
      options.tracesSampleRate = 1.0;
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child:
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider.value(value: PurchaseService.instance),
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
  late final _router = AppRouter.createRouter(widget.userProvider);
  StreamSubscription<PurchaseEvent>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    // Refresh balance whenever a purchase completes — even if the sheet
    // is no longer open.
    _purchaseSub = PurchaseService.instance.events.listen((event) {
      if (event is PurchaseSuccess) {
        widget.userProvider.refreshUser();
      }
    });
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

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

