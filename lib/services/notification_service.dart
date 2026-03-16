import 'dart:async';


import 'package:beerpongapp/util/app_logger.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
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
      // We request permissions via firebase_messaging, not here.
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

    // Create the Android notification channel so that FCM background messages
    // (which bypass Flutter) are also delivered to the correct channel.
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
  /// Requests OS notification permission, saves the FCM token to Firestore,
  /// and wires up all message handlers.
  Future<void> initForUser(String userId) async {
    await _requestPermission();
    await _saveToken(userId);
    _listenToTokenRefresh(userId);
    _setupMessageHandlers();
  }

  /// Call on logout.
  /// Removes this device's FCM token from Firestore so the user stops
  /// receiving notifications on this device.
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
    final token = await _messaging.getToken();
    if (token == null) {
      AppLogger.warning('[FCM] getToken() returned null — skipping save');
      return;
    }
    _currentToken = token;
    await FirestoreService.instance.saveFcmToken(userId, token);
    AppLogger.info('[FCM] Token saved for user $userId');
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

    // Foreground: FCM won't show a banner automatically — we display one via
    // flutter_local_notifications for a consistent cross-platform experience.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap: app was in the background when the notification arrived;
    // user tapped the system banner.
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // Terminated tap: app was closed; notification opened it.
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
      type: message.data['type'] ?? '',
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String type,
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
      // Use a stable ID derived from the current second to avoid stacking
      // identical notifications while still replacing outdated ones.
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: type,
    );
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  void _onLocalNotificationTap(NotificationResponse response) {
    _routeByType(response.payload ?? '');
  }

  void _routeFromMessage(RemoteMessage message) {
    _routeByType(message.data['type'] ?? '');
  }

  /// Routes to the correct in-app screen based on the notification [type].
  /// Routes for Phase 3 screens (/invitations, /waiting) will be active once
  /// those screens are added to the router.
  void _routeByType(String type) {
    switch (type) {
      case 'game_invitation':
        AppRouter.router.go('/invitations');
      case 'invitation_accepted':
      case 'invitation_declined':
        // Host is still in the lobby — the Firestore listener there already
        // updated the slot UI. No additional navigation needed.
        break;
      default:
        break;
    }
  }
}
