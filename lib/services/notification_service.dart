import 'dart:async';
import 'dart:convert';

import 'package:beerpongapp/util/app_logger.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:beerpongapp/util/router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler required by firebase_messaging for messages that arrive
/// when the app is terminated or in the background.
/// Must be a top-level function (not a class method) and annotated with
/// @pragma('vm:entry-point') so the Dart VM keeps it alive in the background
/// isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs (the plugin
  // guarantees it), so no initializeApp() call is needed here.
  AppLogger.info('[FCM background] type=${message.data["type"]}');
}

/// Manages the full FCM lifecycle: permission requests, token
/// save/refresh/remove, foreground notification display via
/// flutter_local_notifications, and in-app routing on notification tap.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'beerpong_invitations';
  static const _channelName = 'Game Invitations';

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _messageHandlersSetup = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Call once in [main] before [runApp] to set up the local notification
  /// plugin and create the Android notification channel.
  Future<void> initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );
  }

  /// Call after a successful login.
  Future<void> initForUser(String userId) async {
    await _requestPermission();
    await _saveToken(userId);
    _listenToTokenRefresh(userId);
    _setupMessageHandlers();
  }

  /// Call on logout.
  Future<void> removeTokenForUser(String userId) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (_currentToken != null) {
      await FirestoreService.instance.removeFcmToken(userId, _currentToken!);
      _currentToken = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info(
        '[FCM] Permission status: ${settings.authorizationStatus.name}');
  }

  // ---------------------------------------------------------------------------
  // Token lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        AppLogger.warning('[FCM] getToken() returned null — skipping save');
        return;
      }
      _currentToken = token;
      await FirestoreService.instance.saveFcmToken(userId, token);
      AppLogger.info('[FCM] Token saved for user $userId');
    } catch (e) {
      // On iOS without Push Notifications entitlement (e.g. personal dev team),
      // getToken() throws apns-token-not-set. Log and continue gracefully.
      AppLogger.warning('[FCM] getToken() failed — $e');
    }
  }

  void _listenToTokenRefresh(String userId) {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      AppLogger.info('[FCM] Token refreshed for user $userId');
      if (_currentToken != null) {
        await FirestoreService.instance.removeFcmToken(userId, _currentToken!);
      }
      _currentToken = newToken;
      await FirestoreService.instance.saveFcmToken(userId, newToken);
    });
  }

  // ---------------------------------------------------------------------------
  // Message handlers
  // ---------------------------------------------------------------------------

  void _setupMessageHandlers() {
    if (_messageHandlersSetup) return;
    _messageHandlersSetup = true;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    unawaited(_messaging.getInitialMessage().then((msg) {
      if (msg != null) _routeFromMessage(msg);
    }));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    AppLogger.info('[FCM foreground] type=${message.data["type"]}');

    await _showLocalNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      data: message.data.cast<String, String>(),
    );
  }

  /// Shows a local banner. The full [data] map is JSON-encoded as the payload
  /// so that fields like [gameId] survive the round-trip to [_onLocalNotificationTap].
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  void _onLocalNotificationTap(NotificationResponse response) {
    try {
      final raw =
          jsonDecode(response.payload ?? '{}') as Map<String, dynamic>;
      final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      _routeByType(data['type'] ?? '', data);
    } catch (_) {
      // Legacy plain-string payload fallback.
      _routeByType(response.payload ?? '', {});
    }
  }

  void _routeFromMessage(RemoteMessage message) {
    _routeByType(
        message.data['type'] ?? '', message.data.cast<String, String>());
  }

  /// Routes to the correct in-app screen based on notification [type].
  ///
  /// | type                  | action                                          |
  /// |-----------------------|-------------------------------------------------|
  /// | game_invitation       | → /invitations (recipient views pending invites)|
  /// | invitation_accepted   | → /home (host: lobby listener already updated)  |
  /// | invitation_declined   | → /home (host: lobby listener already updated)  |
  /// | game_started          | → /waiting (recipient joins; auto-enters /game) |
  void _routeByType(String type, Map<String, String> data) {
    AppLogger.info('[FCM route] type=$type');
    switch (type) {
      case 'game_invitation':
        AppRouter.router.go('/invitations');
      case 'invitation_accepted':
      case 'invitation_declined':
        // The lobby's Firestore stream already updated the slot UI while the
        // host was in GameModeDetailsScreen. If they tapped the notification
        // from outside the app, bring them home.
        AppRouter.router.go('/home');
      case 'game_started':
        final gameId = data['gameId'] ?? '';
        final hostName = data['hostName'] ?? '';
        AppRouter.router.go(
          '/waiting',
          extra: WaitingArgs(gameId: gameId, hostName: hostName),
        );
      default:
        break;
    }
  }
}
