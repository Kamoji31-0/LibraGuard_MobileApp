import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'borrow_service.dart';
import 'notification_service.dart';
import 'pc_service.dart';

class NotificationCacheService {
  static const _borrowKey = 'lg_cache_borrow_status';
  static const _pcKey = 'lg_cache_pc_status';
  static const _gateKey = 'lg_cache_gate_logs';

  Future<Map<String, String>> _loadMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMap(String key, Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  String _norm(String s) => s.toLowerCase().trim();

  bool _isPending(String s) => _norm(s).contains('pending');
  bool _isApproved(String s) =>
      _norm(s).contains('approved') || _norm(s).contains('checked out');
  bool _isRejected(String s) => _norm(s).contains('rejected');
  bool _isCancelled(String s) => _norm(s).contains('cancelled');
  bool _isActive(String s) => _norm(s) == 'active';
  bool _isCompleted(String s) => _norm(s).contains('completed');

  /// Call immediately after a new borrow request is created, so the cache
  /// has a baseline status to diff against. Without this, a request that
  /// gets approved/rejected before the next poll/refresh cycle would be
  /// seen for the first time already in its new state, and the transition
  /// (and its notification) would be missed entirely.
  Future<void> seedBorrowStatus(String txId, String status) async {
    final cache = await _loadMap(_borrowKey);
    if (cache.containsKey(txId)) return; // don't clobber an existing entry
    cache[txId] = status;
    await _saveMap(_borrowKey, cache);
  }

  /// Same idea as [seedBorrowStatus] but for PC session reservations.
  Future<void> seedPcStatus(String sessId, String status) async {
    final cache = await _loadMap(_pcKey);
    if (cache.containsKey(sessId)) return;
    cache[sessId] = status;
    await _saveMap(_pcKey, cache);
  }

  Future<void> checkBorrowChanges(List<BorrowTransaction> fresh) async {
    final cache = await _loadMap(_borrowKey);
    final updated = Map<String, String>.from(cache);

    for (final tx in fresh) {
      final prev = cache[tx.id];
      final curr = tx.status;

      if (prev == null) {
        updated[tx.id] = curr;
        continue;
      }

      if (_norm(prev) == _norm(curr)) continue;

      if (_isPending(prev) && _isApproved(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'borrow',
          status: 'approved',
          itemTitle: tx.bookTitle,
          id: tx.id,
        );
      } else if (_isPending(prev) && _isRejected(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'borrow',
          status: 'rejected',
          itemTitle: tx.bookTitle,
          id: tx.id,
        );
      } else if (!_isCancelled(prev) && _isCancelled(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'borrow',
          status: 'cancelled_borrow',
          itemTitle: tx.bookTitle,
          id: tx.id,
        );
      }

      updated[tx.id] = curr;
    }

    await _saveMap(_borrowKey, updated);
  }

  Future<void> checkPcChanges(List<PcSession> fresh) async {
    final cache = await _loadMap(_pcKey);
    final updated = Map<String, String>.from(cache);

    for (final sess in fresh) {
      final prev = cache[sess.id];
      final curr = sess.status;

      if (prev == null) {
        updated[sess.id] = curr;
        continue;
      }

      if (_norm(prev) == _norm(curr)) continue;

      if (_isPending(prev) && _isActive(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'pc',
          status: 'active',
          itemTitle: sess.computerName,
          id: sess.id,
        );
      } else if (_isActive(prev) && _isCompleted(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'pc',
          status: 'completed',
          itemTitle: sess.computerName,
          id: sess.id,
        );
      } else if (!_isCancelled(prev) && _isCancelled(curr)) {
        await NotificationService.instance.showStatusNotification(
          type: 'pc',
          status: 'cancelled_pc',
          itemTitle: sess.computerName,
          id: sess.id,
        );
      }

      updated[sess.id] = curr;
    }

    await _saveMap(_pcKey, updated);
  }

  Future<void> checkGateChanges(List<Map<String, dynamic>> fresh) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> cache = {};
    try {
      final raw = prefs.getString(_gateKey);
      if (raw != null) {
        cache = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}

    final isFirstSeed = cache.isEmpty;
    final updated = Map<String, dynamic>.from(cache);

    for (final log in fresh) {
      final logId = log['id']?.toString() ??
          log['_id']?.toString() ??
          '${log['timeIn']}_${log['lane']}';
      if (logId.isEmpty) continue;

      final timeIn = log['timeIn']?.toString() ?? '';
      final timeOut = log['timeOut']?.toString();
      final lane = log['lane']?.toString() ?? 'N/A';
      final hasTimeOut = timeOut != null &&
          timeOut.isNotEmpty &&
          timeOut != 'null' &&
          timeOut != 'Active';

      final prev = cache[logId];

      if (prev == null) {
        if (!isFirstSeed && timeIn.isNotEmpty) {
          await NotificationService.instance.showGateNotification(
            logId: logId,
            timeIn: timeIn,
            timeOut: timeOut,
            lane: lane,
            isTimeOut: false,
          );
        }
        updated[logId] = {
          'timeIn': timeIn,
          'timeOut': timeOut,
          'notifiedIn': !isFirstSeed,
          'notifiedOut': false,
        };
        continue;
      }

      final prevMap = Map<String, dynamic>.from(prev as Map);
      final prevHadOut = prevMap['timeOut'] != null &&
          prevMap['timeOut'].toString().isNotEmpty &&
          prevMap['timeOut'] != 'null' &&
          prevMap['timeOut'] != 'Active';
      final alreadyNotifiedOut = prevMap['notifiedOut'] == true;

      if (hasTimeOut && !prevHadOut && !alreadyNotifiedOut) {
        await NotificationService.instance.showGateNotification(
          logId: logId,
          timeIn: timeIn,
          timeOut: timeOut,
          lane: lane,
          isTimeOut: true,
        );
        updated[logId] = {
          'timeIn': timeIn,
          'timeOut': timeOut,
          'notifiedIn': prevMap['notifiedIn'] ?? true,
          'notifiedOut': true,
        };
      } else {
        updated[logId] = {
          'timeIn': timeIn,
          'timeOut': timeOut,
          'notifiedIn': prevMap['notifiedIn'] ?? true,
          'notifiedOut': prevMap['notifiedOut'] ?? false,
        };
      }
    }

    await prefs.setString(_gateKey, jsonEncode(updated));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_borrowKey);
    await prefs.remove(_pcKey);
    await prefs.remove(_gateKey);
  }
}
