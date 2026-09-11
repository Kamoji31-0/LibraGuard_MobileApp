import 'package:workmanager/workmanager.dart';

import 'auth_service.dart';
import 'borrow_service.dart';
import 'notification_cache_service.dart';
import 'notification_service.dart';
import 'pc_service.dart';

const _statusPollTask = 'lg-status-poll';
const _gatePollTask = 'lg-gate-poll';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await NotificationService.instance.initialize(handleLaunchDetails: false);

    final token = await AuthService().getToken();
    if (token == null) return true;

    switch (taskName) {
      case 'pollStatusChanges':
        final txs =
            await BorrowService().fetchMyTransactions(forceRefresh: true);
        await NotificationCacheService().checkBorrowChanges(txs);

        final sessions = await PcService().fetchMySessions();
        await NotificationCacheService().checkPcChanges(sessions);

        for (final s in sessions) {
          if (s.isActive) {
            await NotificationService.instance.schedulePcSessionAlarm(s);
          }
        }
        break;

      case 'pollGateLogs':
        final logs = await AuthService().getGateLogs();
        await NotificationCacheService().checkGateChanges(logs);
        break;
    }
    return true;
  });
}

Future<void> registerBackgroundPollTasks() async {
  await Workmanager().registerPeriodicTask(
    _statusPollTask,
    'pollStatusChanges',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  await Workmanager().registerPeriodicTask(
    _gatePollTask,
    'pollGateLogs',
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 7),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> cancelBackgroundPollTasks() async {
  await Workmanager().cancelByUniqueName(_statusPollTask);
  await Workmanager().cancelByUniqueName(_gatePollTask);
}
