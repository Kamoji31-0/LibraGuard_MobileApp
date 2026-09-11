import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'borrow_service.dart';
import 'pc_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String? subtitle;
  final String type; // 'deadline' | 'pc_alarm' | 'status' | 'gate'
  final DateTime firedAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.firedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'firedAt': firedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        type: json['type'] as String,
        firedAt: DateTime.parse(json['firedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

// Global navigator key so notification taps can navigate even when they
// fire from outside the widget tree (background/terminated callbacks).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsLogKey = 'notifications_log_list';

  // [handleLaunchDetails] is only safe to run when a real Flutter UI/widget
  // tree exists (i.e. app started from main()). The WorkManager background
  // isolate (see background_task.dart) also calls initialize() but has no
  // UI, so it passes false to skip navigation-related setup.
  Future<void> initialize({bool handleLaunchDetails = true}) async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details.payload);
      },
    );

    if (handleLaunchDetails) {
      // If the app was fully closed and got launched by tapping a
      // notification, jump straight to the relevant screen once the
      // first frame is up.
      final NotificationAppLaunchDetails? launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final String? payload = launchDetails?.notificationResponse?.payload;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(payload);
        });
      }
    }

    // Create default channels for Android
    await _createNotificationChannels();
  }

  void _handleNotificationTap(String? payload) {
    switch (payload) {
      case 'deadline':
        navigatorKey.currentState?.pushNamed('/profile/borrowing');
        break;
      case 'pc_alarm':
      case 'status_pc':
        navigatorKey.currentState?.pushNamed('/profile/computer');
        break;
      case 'status_borrow':
        navigatorKey.currentState?.pushNamed('/profile/borrowing');
        break;
      case 'gate':
        navigatorKey.currentState?.pushNamed('/profile/gate');
        break;
      default:
        navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    // 1. Book Deadlines Channel
    const AndroidNotificationChannel deadlinesChannel =
        AndroidNotificationChannel(
      'lg_deadlines',
      'Book Deadlines',
      description: 'Reminders for book pickup and return due dates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // 2. PC Session Alarm Channel (max priority + custom sound/buzzer via system alarm)
    const AndroidNotificationChannel pcAlarmChannel =
        AndroidNotificationChannel(
      'lg_pc_alarm',
      'PC Session Alarm',
      description: 'High priority alerts when computer sessions are ending',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      sound:
          UriAndroidNotificationSound("content://settings/system/alarm_alert"),
    );

    // 3. Status Updates Channel
    const AndroidNotificationChannel statusChannel = AndroidNotificationChannel(
      'lg_status',
      'Status Updates',
      description: 'Approval/rejection notifications for borrow/PC requests',
      importance: Importance.defaultImportance,
      enableVibration: true,
    );

    // 4. Gate Log Channel
    const AndroidNotificationChannel gateChannel = AndroidNotificationChannel(
      'lg_gate',
      'Gate Logs',
      description: 'Instant notification on entry/exit gate records',
      importance: Importance.defaultImportance,
      enableVibration: true,
    );

    await androidImplementation.createNotificationChannel(deadlinesChannel);
    await androidImplementation.createNotificationChannel(pcAlarmChannel);
    await androidImplementation.createNotificationChannel(statusChannel);
    await androidImplementation.createNotificationChannel(gateChannel);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Scheduled Notifications
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> scheduleBookDeadlines(List<BorrowTransaction> txs) async {
    // Clean up any previously scheduled notifications
    await _cancelNotificationsByRange(10000, 14000);

    for (final tx in txs) {
      final int txHash = tx.id.hashCode.abs() % 8000;

      // Only schedule notifications for PENDING or APPROVED requests
      if (!tx.status.toLowerCase().contains('pending') &&
          !tx.status.toLowerCase().contains('approved') &&
          !tx.status.toLowerCase().contains('checked out')) {
        continue;
      }

      // Schedule Pickup Deadlines if pending
      if (tx.status.toLowerCase().contains('pending') &&
          tx.pickupDeadline.isNotEmpty) {
        try {
          final DateTime deadline = DateTime.parse(tx.pickupDeadline).toLocal();

          // 1. One day before pickup deadline (9:00 AM)
          final DateTime dayBefore =
              DateTime(deadline.year, deadline.month, deadline.day - 1, 9, 0);
          if (dayBefore.isAfter(DateTime.now())) {
            await _schedule(
              id: 10000 + txHash,
              title: '⏰ Pickup Reminder',
              body: 'Don\'t forget to pick up "${tx.bookTitle}" by tomorrow!',
              scheduledTime: dayBefore,
              channelId: 'lg_deadlines',
              channelName: 'Book Deadlines',
              payload: 'deadline',
            );
          }

          // 2. Day of pickup deadline (8:00 AM)
          final DateTime dayOf =
              DateTime(deadline.year, deadline.month, deadline.day, 8, 0);
          if (dayOf.isAfter(DateTime.now())) {
            await _schedule(
              id: 11000 + txHash,
              title: '⚠️ Last Day to Pick Up',
              body: 'Today is your last day to pick up "${tx.bookTitle}".',
              scheduledTime: dayOf,
              channelId: 'lg_deadlines',
              channelName: 'Book Deadlines',
              payload: 'deadline',
            );
          }
        } catch (_) {}
      }

      // Schedule Return Deadlines if approved/checked out
      if ((tx.status.toLowerCase().contains('approved') ||
              tx.status.toLowerCase().contains('checked out')) &&
          tx.dueDate.isNotEmpty) {
        try {
          final DateTime due = DateTime.parse(tx.dueDate).toLocal();

          // 3. One day before due date (9:00 AM)
          final DateTime dueDayBefore =
              DateTime(due.year, due.month, due.day - 1, 9, 0);
          if (dueDayBefore.isAfter(DateTime.now())) {
            await _schedule(
              id: 12000 + txHash,
              title: '📚 Book Due Tomorrow',
              body: '"${tx.bookTitle}" is due for return tomorrow.',
              scheduledTime: dueDayBefore,
              channelId: 'lg_deadlines',
              channelName: 'Book Deadlines',
              payload: 'deadline',
            );
          }

          // 4. Day of due date (9:00 AM)
          final DateTime dueDayOf =
              DateTime(due.year, due.month, due.day, 9, 0);
          if (dueDayOf.isAfter(DateTime.now())) {
            await _schedule(
              id: 13000 + txHash,
              title: '🚨 Book Due Today',
              body:
                  '"${tx.bookTitle}" is due today. Please return it to avoid penalties.',
              scheduledTime: dueDayOf,
              channelId: 'lg_deadlines',
              channelName: 'Book Deadlines',
              payload: 'deadline',
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<void> schedulePcSessionAlarm(PcSession sess) async {
    final int sessHash = sess.id.hashCode.abs() % 8000;
    await cancelPcAlarm(sess.id);

    if (!sess.status.toLowerCase().contains('active') ||
        sess.endTime == null ||
        sess.endTime!.isEmpty) {
      return;
    }

    try {
      final DateTime end = DateTime.parse(sess.endTime!).toLocal();

      // 1. 5 minutes before end
      final DateTime warningTime = end.subtract(const Duration(minutes: 5));
      if (warningTime.isAfter(DateTime.now())) {
        await _scheduleAlarm(
          id: 20000 + sessHash,
          title: '⚠️ PC Session Ending Soon',
          body:
              '5 minutes left on ${sess.computerName}! Please save your work.',
          scheduledTime: warningTime,
          payload: 'pc_alarm',
        );
      }

      // 2. Exact end time
      if (end.isAfter(DateTime.now())) {
        await _scheduleAlarm(
          id: 21000 + sessHash,
          title: '🔴 PC Session Ended',
          body: 'Your reserved time on ${sess.computerName} has expired.',
          scheduledTime: end,
          payload: 'pc_alarm',
        );
      }
    } catch (_) {}
  }

  Future<void> cancelBookSchedule(String txId) async {
    final int hash = txId.hashCode.abs() % 8000;
    await _notifications.cancel(id: 10000 + hash);
    await _notifications.cancel(id: 11000 + hash);
    await _notifications.cancel(id: 12000 + hash);
    await _notifications.cancel(id: 13000 + hash);
  }

  Future<void> cancelPcAlarm(String sessId) async {
    final int hash = sessId.hashCode.abs() % 8000;
    await _notifications.cancel(id: 20000 + hash);
    await _notifications.cancel(id: 21000 + hash);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Immediate Notifications
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> showStatusNotification({
    required String type,
    required String status,
    required String itemTitle,
    required String id,
  }) async {
    final int idHash = id.hashCode.abs() % 8000;
    final int notifId = (type == 'borrow' ? 30000 : 31000) + idHash;

    String bodyText = '';
    if (type == 'borrow') {
      if (status.toLowerCase().contains('approved')) {
        bodyText = 'Your request for "$itemTitle" has been approved!';
      } else if (status.toLowerCase().contains('rejected')) {
        bodyText = 'Your request for "$itemTitle" was rejected.';
      } else if (status.toLowerCase().contains('cancelled')) {
        bodyText = 'Your request for "$itemTitle" was cancelled.';
      } else {
        bodyText = 'Your request status updated to: $status';
      }
    } else {
      if (status.toLowerCase().contains('active')) {
        bodyText = 'Your PC session for "$itemTitle" is now active!';
      } else if (status.toLowerCase().contains('completed')) {
        bodyText = 'Your PC session for "$itemTitle" has completed.';
      } else if (status.toLowerCase().contains('cancelled')) {
        bodyText = 'Your PC reservation for "$itemTitle" was cancelled.';
      } else {
        bodyText = 'Your PC session status updated to: $status';
      }
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lg_status',
      'Status Updates',
      channelDescription: 'Approval/rejection updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: notifId,
      title: type == 'borrow'
          ? '📚 Borrow Request Update'
          : '💻 PC Reservation Update',
      body: bodyText,
      notificationDetails: details,
      payload: type == 'borrow' ? 'status_borrow' : 'status_pc',
    );

    // Save to dynamic log list
    await logNotification(NotificationItem(
      id: id,
      title: type == 'borrow' ? 'Borrow Update' : 'PC Session Update',
      subtitle: bodyText,
      type: 'status',
      firedAt: DateTime.now(),
    ));
  }

  Future<void> showGateNotification({
    required String timeIn,
    required String? timeOut,
    required String lane,
    required String logId,
    required bool isTimeOut,
  }) async {
    final int notifId = isTimeOut
        ? 41000 + logId.hashCode.abs() % 8000
        : 40000 + logId.hashCode.abs() % 8000;

    final bool isEntry = !isTimeOut;
    final String timeStr =
        _formatTimeString(isEntry ? timeIn : (timeOut ?? ''));

    final String title =
        isEntry ? '🚪 Library Check-In' : '🚪 Library Check-Out';
    final String bodyText = isEntry
        ? 'Welcome to the library! Checked in at Lane $lane — $timeStr.'
        : 'Thank you for visiting! Checked out at Lane $lane — $timeStr.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lg_gate',
      'Gate Logs',
      channelDescription: 'RFID entry/exit notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: notifId,
      title: title,
      body: bodyText,
      notificationDetails: details,
      payload: 'gate',
    );

    await logNotification(NotificationItem(
      id: logId,
      title: title,
      subtitle: bodyText,
      type: 'gate',
      firedAt: DateTime.now(),
    ));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Scheduling Core Methods
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lg_pc_alarm',
      'PC Session Alarm',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      sound:
          UriAndroidNotificationSound("content://settings/system/alarm_alert"),
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _cancelNotificationsByRange(int start, int end) async {
    for (int i = start; i < end; i++) {
      try {
        await _notifications.cancel(id: i);
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Notification Log storage (dynamic in-app center)
  // ───────────────────────────────────────────────────────────────────────────

  Future<String?> _getCurrentUserId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_profile');
      if (data != null) {
        final Map<String, dynamic> profile = jsonDecode(data);
        final String? userId = (profile['id'] ?? profile['_id'] ?? profile['studentId'] ?? profile['email'])?.toString();
        if (userId != null && userId.isNotEmpty) {
          return userId;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> _getLogKey() async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      return _notificationsLogKey;
    }
    return '${_notificationsLogKey}_$userId';
  }

  Future<void> logNotification(NotificationItem item) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = await _getLogKey();
      final List<NotificationItem> currentList = await getStoredNotifications();
      
      // Prevent duplicates
      if (currentList.any((n) => n.id == item.id)) {
        return;
      }

      currentList.insert(0, item); // Keep latest at top

      // Cap at 100 history items to save space
      if (currentList.length > 100) {
        currentList.removeLast();
      }

      final String rawJson =
          jsonEncode(currentList.map((e) => e.toJson()).toList());
      await prefs.setString(key, rawJson);
    } catch (_) {}
  }

  Future<List<NotificationItem>> getStoredNotifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = await _getLogKey();
      final String? data = prefs.getString(key);
      if (data == null) return [];

      final List<dynamic> rawList = jsonDecode(data) as List;
      return rawList
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    final List<NotificationItem> list = await getStoredNotifications();
    return list.where((n) => !n.isRead).length;
  }

  Future<void> clearAllStored() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = await _getLogKey();
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = await _getLogKey();
      final List<NotificationItem> currentList = await getStoredNotifications();
      bool updated = false;
      for (final item in currentList) {
        if (item.id == id) {
          item.isRead = true;
          updated = true;
        }
      }
      if (updated) {
        final String rawJson =
            jsonEncode(currentList.map((e) => e.toJson()).toList());
        await prefs.setString(key, rawJson);
      }
    } catch (_) {}
  }

  Future<void> syncNotificationsWithAccount() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) return;

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Reconstruct from Borrow Transactions
      try {
        final txs = await BorrowService().getPersistentCachedTransactions();
        for (final tx in txs) {
          String bodyText = '';
          if (tx.status.toLowerCase().contains('approved') || tx.status.toLowerCase().contains('checked out')) {
            bodyText = 'Your request for "${tx.bookTitle}" has been approved!';
          } else if (tx.status.toLowerCase().contains('rejected')) {
            bodyText = 'Your request for "${tx.bookTitle}" was rejected.';
          } else if (tx.status.toLowerCase().contains('cancelled')) {
            bodyText = 'Your request for "${tx.bookTitle}" was cancelled.';
          } else if (tx.status.toLowerCase().contains('pending')) {
            bodyText = 'Your request for "${tx.bookTitle}" is pending review.';
          } else {
            continue;
          }

          DateTime fired = DateTime.now();
          if (tx.borrowDate.isNotEmpty) {
            fired = DateTime.tryParse(tx.borrowDate) ?? DateTime.now();
          }

          await logNotification(NotificationItem(
            id: 'sync_borrow_${tx.id}',
            title: 'Borrow Update',
            subtitle: bodyText,
            type: 'status',
            firedAt: fired,
            isRead: true,
          ));
        }
      } catch (_) {}

      // 2. Reconstruct from PC Sessions
      try {
        final sessions = await PcService().getPersistentCachedSessions();
        for (final sess in sessions) {
          String bodyText = '';
          if (sess.status.toLowerCase().contains('active')) {
            bodyText = 'Your PC session for "${sess.computerName}" is now active!';
          } else if (sess.status.toLowerCase().contains('completed')) {
            bodyText = 'Your PC session for "${sess.computerName}" has completed.';
          } else if (sess.status.toLowerCase().contains('cancelled')) {
            bodyText = 'Your PC reservation for "${sess.computerName}" was cancelled.';
          } else if (sess.status.toLowerCase().contains('pending')) {
            bodyText = 'Your PC reservation for "${sess.computerName}" is pending.';
          } else {
            continue;
          }

          DateTime fired = DateTime.now();
          if (sess.startTime != null && sess.startTime!.isNotEmpty) {
            fired = DateTime.tryParse(sess.startTime!) ?? DateTime.now();
          } else if (sess.createdAt != null && sess.createdAt!.isNotEmpty) {
            fired = DateTime.tryParse(sess.createdAt!) ?? DateTime.now();
          }

          await logNotification(NotificationItem(
            id: 'sync_pc_${sess.id}',
            title: 'PC Session Update',
            subtitle: bodyText,
            type: 'status',
            firedAt: fired,
            isRead: true,
          ));
        }
      } catch (_) {}

      // 3. Reconstruct from Gate Logs
      try {
        final gateLogsRaw = prefs.getString('cached_gate_logs');
        if (gateLogsRaw != null) {
          final List<dynamic> gateLogs = jsonDecode(gateLogsRaw);
          for (final log in gateLogs) {
            final logMap = Map<String, dynamic>.from(log as Map);
            final logId = logMap['id']?.toString() ??
                logMap['_id']?.toString() ??
                '${logMap['timeIn']}_${logMap['lane']}';
            if (logId.isEmpty) continue;

            final timeIn = logMap['timeIn']?.toString() ?? '';
            final timeOut = logMap['timeOut']?.toString();
            final lane = logMap['lane']?.toString() ?? 'N/A';

            if (timeIn.isNotEmpty) {
              DateTime fired = DateTime.tryParse(timeIn) ?? DateTime.now();
              final timeStr = _formatTimeString(timeIn);
              await logNotification(NotificationItem(
                id: 'sync_gate_${logId}_in',
                title: '🚪 Library Check-In',
                subtitle: 'Welcome to the library! Checked in at Lane $lane — $timeStr.',
                type: 'gate',
                firedAt: fired,
                isRead: true,
              ));
            }

            if (timeOut != null && timeOut.isNotEmpty && timeOut != 'null' && timeOut != 'Active') {
              DateTime fired = DateTime.tryParse(timeOut) ?? DateTime.now();
              final timeStr = _formatTimeString(timeOut);
              await logNotification(NotificationItem(
                id: 'sync_gate_${logId}_out',
                title: '🚪 Library Check-Out',
                subtitle: 'Thank you for visiting! Checked out at Lane $lane — $timeStr.',
                type: 'gate',
                firedAt: fired,
                isRead: true,
              ));
            }
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> showLibraryFullNotification() async {
    const int notifId = 50000;
    const String title = '🚨 Library Capacity Alert';
    const String bodyText =
        'The library has reached its maximum capacity of 300 seats.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lg_capacity',
      'Capacity Alerts',
      channelDescription: 'Alerts when library is full',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: notifId,
      title: title,
      body: bodyText,
      notificationDetails: details,
    );

    await logNotification(NotificationItem(
      id: 'capacity_full_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Library Capacity Full',
      subtitle: bodyText,
      type: 'status',
      firedAt: DateTime.now(),
    ));
  }

  String _formatTimeString(String rawIso) {
    try {
      final DateTime dt = DateTime.parse(rawIso).toLocal();
      final String hour =
          (dt.hour == 0 || dt.hour == 12) ? '12' : (dt.hour % 12).toString();
      final String minute = dt.minute.toString().padLeft(2, '0');
      final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } catch (_) {
      return rawIso;
    }
  }
}
