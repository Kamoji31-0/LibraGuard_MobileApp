import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_item.dart';
import 'borrow_service.dart';
import 'pc_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const _logKey = 'lg_notification_log';
  static bool _initialized = false;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'lg_deadlines',
      'Book Deadlines',
      description: 'Pickup and due date reminders',
      importance: Importance.high,
      enableVibration: true,
    ));

    await android.createNotificationChannel(AndroidNotificationChannel(
      'lg_pc_alarm',
      'PC Session Alarm',
      description: 'PC session end warnings and buzzer',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 1000]),
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'lg_status',
      'Status Updates',
      description: 'Borrow and PC reservation status changes',
      importance: Importance.defaultImportance,
      enableVibration: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'lg_gate',
      'Gate Entry/Exit',
      description: 'Library gate RFID tap events',
      importance: Importance.defaultImportance,
      enableVibration: true,
    ));
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _notifId(int base, String entityId) =>
      base + entityId.hashCode.abs() % 8000;

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime _atNineAm(DateTime date) =>
      DateTime(date.year, date.month, date.day, 9);

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    String type = 'deadline',
    String? subtitle,
    bool fullScreen = false,
  }) async {
    if (when.isBefore(DateTime.now())) return;

    final androidDetails = fullScreen
        ? AndroidNotificationDetails(
            'lg_pc_alarm',
            'PC Session Alarm',
            channelDescription: 'PC session end warnings and buzzer',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            playSound: true,
            enableVibration: true,
            vibrationPattern:
                Int64List.fromList([0, 500, 200, 500, 200, 1000]),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            autoCancel: true,
          )
        : AndroidNotificationDetails(
            channelId,
            channelId == 'lg_deadlines' ? 'Book Deadlines' : channelId,
            importance: channelId == 'lg_deadlines'
                ? Importance.high
                : Importance.defaultImportance,
            priority: channelId == 'lg_deadlines'
                ? Priority.high
                : Priority.defaultPriority,
            enableVibration: true,
          );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleBookDeadlines(List<BorrowTransaction> txs) async {
    await initialize();
    for (final tx in txs) {
      if (tx.isReturned || tx.isCancelled || tx.isRejected) continue;

      final pickup = _parseDate(tx.pickupDeadline);
      if (pickup != null && !tx.isApproved) {
        await _scheduleAt(
          id: _notifId(10000, tx.id),
          title: 'Pickup Reminder',
          body:
              'Pick up "${tx.bookTitle}" by tomorrow — deadline is ${_formatDate(pickup)}.',
          when: _atNineAm(pickup.subtract(const Duration(days: 1))),
          channelId: 'lg_deadlines',
          subtitle: tx.bookTitle,
        );
        await _scheduleAt(
          id: _notifId(11000, tx.id),
          title: 'Pickup Due Today',
          body:
              'Today is the last day to pick up "${tx.bookTitle}". Visit the library before closing.',
          when: _atNineAm(pickup),
          channelId: 'lg_deadlines',
          subtitle: tx.bookTitle,
        );
      }

      final due = _parseDate(tx.dueDate);
      if (due != null && tx.isApproved && !tx.isReturned) {
        await _scheduleAt(
          id: _notifId(12000, tx.id),
          title: 'Return Reminder',
          body:
              'Return "${tx.bookTitle}" by tomorrow — due date is ${_formatDate(due)}.',
          when: _atNineAm(due.subtract(const Duration(days: 1))),
          channelId: 'lg_deadlines',
          subtitle: tx.bookTitle,
        );
        await _scheduleAt(
          id: _notifId(13000, tx.id),
          title: 'Book Due Today',
          body:
              '"${tx.bookTitle}" is due today. Please return it to avoid penalties.',
          when: _atNineAm(due),
          channelId: 'lg_deadlines',
          subtitle: tx.bookTitle,
        );
      }
    }
  }

  Future<void> schedulePcSessionAlarm(PcSession sess) async {
    await initialize();
    if (!sess.isActive || sess.endTime == null) return;

    final end = _parseDate(sess.endTime!);
    if (end == null || end.isBefore(DateTime.now())) return;

    final warning = end.subtract(const Duration(minutes: 5));
    await _scheduleAt(
      id: _notifId(20000, sess.id),
      title: 'PC Session Ending Soon',
      body:
          'Your session on ${sess.computerName} ends in 5 minutes. Save your work!',
      when: warning,
      channelId: 'lg_pc_alarm',
      type: 'pc_alarm',
      subtitle: sess.computerName,
      fullScreen: true,
    );

    await _scheduleAt(
      id: _notifId(21000, sess.id),
      title: 'PC Session Ended',
      body: 'Your session on ${sess.computerName} has ended. Please log off.',
      when: end,
      channelId: 'lg_pc_alarm',
      type: 'pc_alarm',
      subtitle: sess.computerName,
      fullScreen: true,
    );
  }

  Future<void> cancelBookSchedule(String txId) async {
    await _plugin.cancel(_notifId(10000, txId));
    await _plugin.cancel(_notifId(11000, txId));
    await _plugin.cancel(_notifId(12000, txId));
    await _plugin.cancel(_notifId(13000, txId));
  }

  Future<void> cancelPcAlarm(String sessId) async {
    await _plugin.cancel(_notifId(20000, sessId));
    await _plugin.cancel(_notifId(21000, sessId));
  }

  Future<void> showStatusNotification({
    required String type,
    required String status,
    required String itemTitle,
    required String id,
  }) async {
    await initialize();
    final notifId = type == 'borrow'
        ? _notifId(30000, id)
        : _notifId(31000, id);

    String title;
    String body;
    switch (status) {
      case 'approved':
        title = 'Borrow Request Approved';
        body =
            'Your request for "$itemTitle" was approved! Pick up within 3 days.';
        break;
      case 'rejected':
        title = 'Borrow Request Rejected';
        body =
            'Your request for "$itemTitle" was rejected by the librarian.';
        break;
      case 'cancelled_borrow':
        title = 'Borrow Request Cancelled';
        body = 'Your borrow request for "$itemTitle" was cancelled.';
        break;
      case 'active':
        title = 'PC Session Started';
        body = '$itemTitle is ready! Your session has started.';
        break;
      case 'completed':
        title = 'PC Session Ended';
        body = 'Your session on $itemTitle has ended.';
        break;
      case 'cancelled_pc':
        title = 'PC Reservation Cancelled';
        body = 'Your PC reservation for $itemTitle was cancelled.';
        break;
      default:
        title = 'Status Update';
        body = '$itemTitle — $status';
    }

    await _plugin.show(
      notifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lg_status',
          'Status Updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: true,
        ),
      ),
    );

    await logNotification(NotificationItem(
      id: 'status_${type}_$id',
      title: title,
      subtitle: body,
      type: 'status',
      firedAt: DateTime.now(),
    ));
  }

  Future<void> showGateNotification({
    required String logId,
    required String timeIn,
    required String? timeOut,
    required String lane,
    required bool isTimeOut,
  }) async {
    await initialize();
    final notifId = isTimeOut
        ? _notifId(41000, logId)
        : _notifId(40000, logId);

    final timeStr = isTimeOut ? (timeOut ?? '') : timeIn;
    final formatted = _formatTime(timeStr);
    final title = isTimeOut ? 'Gate Time Out' : 'Gate Time In';
    final body = isTimeOut
        ? 'Time Out at Lane $lane — $formatted. See you next time!'
        : 'Time In at Lane $lane — $formatted. Welcome to the library!';

    await _plugin.show(
      notifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lg_gate',
          'Gate Entry/Exit',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: true,
        ),
      ),
    );

    await logNotification(NotificationItem(
      id: 'gate_${isTimeOut ? 'out' : 'in'}_$logId',
      title: title,
      subtitle: 'Lane $lane · $formatted',
      type: 'gate',
      firedAt: DateTime.now(),
    ));
  }

  Future<void> logNotification(NotificationItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getStoredNotifications();
      existing.insert(0, item);
      if (existing.length > 200) {
        existing.removeRange(200, existing.length);
      }
      await prefs.setString(
        _logKey,
        jsonEncode(existing.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<NotificationItem>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_logKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }

  Future<void> cancelAll() async => clearAll();

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String raw) {
    final dt = _parseDate(raw);
    if (dt == null) return raw;
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min $ampm';
  }
}
