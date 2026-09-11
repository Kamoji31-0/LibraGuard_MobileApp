import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'background_task.dart';
import 'borrow_service.dart';
import 'favorite_service.dart';
import 'notification_cache_service.dart';
import 'notification_service.dart';
import 'pc_service.dart';

/// Call after successful login or when restoring an existing session.
Future<void> setupNotificationsAfterLogin() async {
  if (kIsWeb) return;
  final token = await AuthService().getToken();
  if (token == null) return;

  await NotificationService.instance.requestPermissions();

  final txs = await BorrowService().fetchMyTransactions(forceRefresh: true);
  await NotificationService.instance.scheduleBookDeadlines(txs);
  await NotificationCacheService().checkBorrowChanges(txs);

  final sessions = await PcService().fetchMySessions();
  for (final s in sessions) {
    if (s.isActive) {
      await NotificationService.instance.schedulePcSessionAlarm(s);
    }
  }
  await NotificationCacheService().checkPcChanges(sessions);

  final logs = await AuthService().getGateLogs();
  await NotificationCacheService().checkGateChanges(logs);

  await NotificationService.instance.syncNotificationsWithAccount();

  // Sync favorites from the account
  await FavoriteService().getFavoriteIds();

  await registerBackgroundPollTasks();
}

/// Immediate diff check when app is open or resumed.
Future<void> checkStatusChangesNow() async {
  if (kIsWeb) return;
  final token = await AuthService().getToken();
  if (token == null) return;

  final txs = await BorrowService().fetchMyTransactions(forceRefresh: true);
  await NotificationCacheService().checkBorrowChanges(txs);
  await NotificationService.instance.scheduleBookDeadlines(txs);

  final sessions = await PcService().fetchMySessions();
  await NotificationCacheService().checkPcChanges(sessions);
  for (final s in sessions) {
    if (s.isActive) {
      await NotificationService.instance.schedulePcSessionAlarm(s);
    }
  }

  final logs = await AuthService().getGateLogs();
  await NotificationCacheService().checkGateChanges(logs);

  await NotificationService.instance.syncNotificationsWithAccount();

  // Sync favorites from the account
  await FavoriteService().getFavoriteIds();
}
