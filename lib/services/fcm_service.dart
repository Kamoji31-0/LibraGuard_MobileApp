import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'auth_service.dart';

/// Public VAPID key generated from Firebase Console -> Project Settings -> Cloud Messaging -> Web Push certificates.
const String fcmVapidKey =
    'BHTC0CpFjtDXOYkOgKge3MW6d1AQkThMrEywQQs9PoC1ilSwSqFitcFt3mDNGbhVU9H9je73NaD8vX5msa1EUAg';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
  }

  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Background message data: ${message.data}');
  }

  // Handle parsing FCM background payload
  _handleIncomingMessage(message);
}

void _handleIncomingMessage(RemoteMessage message) {
  final Map<String, dynamic> data = message.data;
  final String? type = data['type']?.toString();
  bool handled = false;

  if (type == 'status_change') {
    final String? entityType = data['entity']?.toString(); // 'borrow' | 'pc'
    final String? status = data['status']?.toString();
    final String? id = data['entityId']?.toString();
    final String? title = data['title']?.toString();

    if (entityType != null && status != null && id != null && title != null) {
      if (!kIsWeb) {
        NotificationService.instance.showStatusNotification(
          type: entityType,
          status: status,
          itemTitle: title,
          id: id,
        );
      } else {
        NotificationService.instance.logNotification(NotificationItem(
          id: id,
          title: entityType == 'borrow' ? 'Borrow Update' : 'PC Session Update',
          subtitle: 'Status updated to: $status for $title',
          type: 'status',
          firedAt: DateTime.now(),
        ));
      }
      handled = true;
    }
  } else if (type == 'gate_log') {
    final String? logId = data['logId']?.toString();
    final String? timeIn = data['timeIn']?.toString();
    final String? timeOut = data['timeOut']?.toString();
    final String? lane = data['lane']?.toString();

    if (logId != null && timeIn != null && lane != null) {
      final bool isOut = timeOut != null && timeOut != 'null' && timeOut.isNotEmpty && timeOut != 'Active';
      if (!kIsWeb) {
        NotificationService.instance.showGateNotification(
          timeIn: timeIn,
          timeOut: timeOut == 'null' ? null : timeOut,
          lane: lane,
          logId: logId,
          isTimeOut: isOut,
        );
      } else {
        NotificationService.instance.logNotification(NotificationItem(
          id: logId,
          title: isOut ? 'Gate Exit Logged' : 'Gate Entry Logged',
          subtitle: 'Lane: $lane | ${isOut ? "Exit: $timeOut" : "Entry: $timeIn"}',
          type: 'gate',
          firedAt: DateTime.now(),
        ));
      }
      handled = true;
    }
  }

  // Fallback: If message wasn't structured as status_change or gate_log,
  // capture the notification so it still appears in the in-app notification center.
  if (!handled) {
    final String? fallbackTitle = message.notification?.title ??
        data['title']?.toString() ??
        data['header']?.toString();
    final String? fallbackBody = message.notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        data['content']?.toString();

    if (fallbackTitle != null && fallbackTitle.isNotEmpty) {
      final String msgId = message.messageId ??
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      NotificationService.instance.logNotification(NotificationItem(
        id: msgId,
        title: fallbackTitle,
        subtitle: fallbackBody,
        type: data['type']?.toString() ?? 'status',
        firedAt: message.sentTime ?? DateTime.now(),
      ));
    }
  }
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Set background message handler (Mobile only; Web uses firebase-messaging-sw.js)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    }

    // 2. Request permissions for iOS / Android 13+ / Web PWA
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 3. Configure foreground presentation options (Mobile only)
    if (!kIsWeb) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 4. Set foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
        print('Foreground message data: ${message.data}');
      }
      _handleIncomingMessage(message);
    });

    // 5. Handle tapping on notifications when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification clicked! Opened app: ${message.messageId}');
      }
      // Can perform custom navigation here depending on notification type
    });

    // 6. Handle notification click that opened the app from terminated state
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state via notification: ${initialMessage.messageId}');
      }
    }

    // 7. Get and save FCM Token
    await refreshAndSaveToken();

    // 8. Listen for token refresh
    _fcm.onTokenRefresh.listen((String token) async {
      await _uploadToken(token);
    });
  }

  Future<void> refreshAndSaveToken() async {
    try {
      final String? token;
      if (kIsWeb) {
        token = await _fcm.getToken(
          vapidKey: fcmVapidKey.isNotEmpty ? fcmVapidKey : null,
        );
      } else {
        token = await _fcm.getToken();
      }
      if (token != null) {
        await _uploadToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _uploadToken(String token) async {
    if (kDebugMode) {
      print('FCM Token generated: $token');
    }
    // Save to SharedPreferences and push to API
    final AuthService authService = AuthService();
    await authService.saveFcmTokenLocally(token);
    await authService.syncFcmTokenWithServer(token);
  }
}
