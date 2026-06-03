import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LibraryComputer {
  final String id;
  final String name;
  final String status;

  LibraryComputer({
    required this.id,
    required this.name,
    required this.status,
  });

  bool get isAvailable =>
      status.toLowerCase() == 'available' || status.toLowerCase() == 'free';

  factory LibraryComputer.fromJson(Map<String, dynamic> json) {
    return LibraryComputer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['pcName']?.toString() ??
          json['label']?.toString() ??
          'Unknown PC',
      status: json['status']?.toString() ?? 'Available',
    );
  }
}

class PcSession {
  final String id;
  final String userId;
  final String computerId;
  final String computerName;
  final String status;
  final String duration;
  final String? startTime;
  final String? endTime;
  final String? createdAt;
  final String? reference;

  PcSession({
    required this.id,
    required this.userId,
    required this.computerId,
    required this.computerName,
    required this.status,
    required this.duration,
    this.startTime,
    this.endTime,
    this.createdAt,
    this.reference,
  });

  bool get isPending => status.toLowerCase().contains('pending');
  bool get isActive => status.toLowerCase() == 'active';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory PcSession.fromJson(Map<String, dynamic> json) {
    final computer = json['computer'] as Map<String, dynamic>?;
    final String compName = computer?['name']?.toString() ??
        json['pcName']?.toString() ??
        json['computerName']?.toString() ??
        'Unknown PC';

String dur = 'N/A';
    final rawDur = json['duration'] ??
                   json['requestedDuration'] ??
                   json['hours'] ??
                   json['sessionHours'] ??
                   json['requestedHours'] ??
                   json['sessionDuration'] ??
                   json['session_hours'] ??
                   json['session_duration'] ??
                   json['timeLimit'] ??
                   json['limit'] ??
                   json['allottedTime'] ??
                   json['usage_hours'] ??
                   json['usageHours'] ??
                   json['session_length'] ??
                   json['length'] ??
                   json['hours_requested'] ??
                   json['requested_hours'];

    if (rawDur != null) {
      if (rawDur is int) {
        final h = rawDur ~/ 60;
        final m = rawDur % 60;
        dur = h > 0 ? '$h Hour${h > 1 ? 's' : ''} ${m > 0 ? '$m Min' : ''}'.trim() : '$m Min';
      } else if (rawDur is double || rawDur is num) {
        double hours = double.parse(rawDur.toString());
        if (hours >= 1.0) {
          int h = hours.floor();
          int m = ((hours - h) * 60).round();
          dur = m > 0 ? '$h Hour${h > 1 ? 's' : ''} $m Min' : '$h Hour${h > 1 ? 's' : ''}';
        } else {
          int m = (hours * 60).round();
          dur = '$m Min';
        }
      } else {
        dur = rawDur.toString();
        final parsed = double.tryParse(dur);
        if (parsed != null) {
          if (parsed >= 1.0) {
            int h = parsed.floor();
            int m = ((parsed - h) * 60).round();
            dur = m > 0 ? '$h Hour${h > 1 ? 's' : ''} $m Min' : '$h Hour${h > 1 ? 's' : ''}';
          } else {
            int m = (parsed * 60).round();
            dur = '$m Min';
          }
        }
      }
    }

if (dur == 'N/A' && json['startTime'] != null && json['endTime'] != null) {
      try {
        final start = DateTime.parse(json['startTime'].toString());
        final end = DateTime.parse(json['endTime'].toString());
        final diff = end.difference(start);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        if (h > 0) {
          dur = '$h Hour${h > 1 ? 's' : ''}${m > 0 ? ' $m Min' : ''}';
        } else {
          dur = '$m Min';
        }
      } catch (_) {}
    }

String? ref = json['reference']?.toString() ?? json['sessionReference']?.toString();
    if (ref == null) {
      final rawStart = json['startTime'] ?? json['start_time'] ?? json['reservationDate'] ?? json['date'];
      if (rawStart != null) {
        try {
          final dt = DateTime.parse(rawStart.toString()).toLocal();
          ref = '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {}
      }
    }

        return PcSession(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['studentId']?.toString() ?? '',
      computerId:
          json['computerId']?.toString() ?? computer?['id']?.toString() ?? '',
      computerName: compName,
      status: json['status']?.toString() ?? 'Pending',
      duration: dur,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      reference: ref,
      createdAt: json['createdAt']?.toString() ??
                 json['created_at']?.toString() ??
                 json['date']?.toString() ??
                 json['reservationDate']?.toString() ??
                 json['reservation_date']?.toString() ??
                 json['startTime']?.toString() ??
                 json['start_time']?.toString(),
    );
  }
}

class PcService {
  static const String _baseUrl = 'https://libraguard-api.onrender.com/api';
  static const String _sessionCacheKey = 'cached_pc_sessions';
  static const String _pcListCacheKey = 'cached_pc_list';

Future<void> _saveSessionsToCache(List<PcSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> rawList = sessions.map((s) => {
        'id': s.id,
        'userId': s.userId,
        'computerId': s.computerId,
        'computerName': s.computerName,
        'status': s.status,
        'duration': s.duration,
        'startTime': s.startTime,
        'endTime': s.endTime,
        'reference': s.reference,
        'createdAt': s.createdAt,
      }).toList();
      await prefs.setString(_sessionCacheKey, jsonEncode(rawList));
    } catch (_) {}
  }

Future<void> _saveComputersToCache(List<dynamic> rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pcListCacheKey, jsonEncode(rawJson));
    } catch (_) {}
  }

Future<List<LibraryComputer>> getPersistentCachedComputers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_pcListCacheKey);
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        return list
            .map((e) => LibraryComputer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

Future<List<PcSession>> getPersistentCachedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_sessionCacheKey);
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        return list.map((e) => PcSession.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

Future<List<LibraryComputer>> fetchComputers() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/computers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['computers'] ?? []);

_saveComputersToCache(list);

        return list
            .map((e) => LibraryComputer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return await getPersistentCachedComputers();
    } catch (e) {
      return await getPersistentCachedComputers();
    }
  }

Future<Map<String, dynamic>> submitReservation({
    required String computerId,
    required int durationMinutes,
  }) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'You are not logged in.'};
    }

final profileRes = await authService.getProfile();
    final userId = profileRes['data']?['id']?.toString() ??
        profileRes['data']?['_id']?.toString() ??
        profileRes['data']?['studentId']?.toString() ??
        '';
    if (userId.isEmpty) {
      return {'success': false, 'message': 'Could not retrieve user ID.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/computers/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'computerId': computerId,
          'hours': durationMinutes / 60.0,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = data is Map && data['data'] != null ? data['data'] : data;
        return {
          'success': true,
          'session':
              raw is Map<String, dynamic> ? PcSession.fromJson(raw) : null,
          'message': 'Reservation submitted successfully!',
        };
      } else {
        return {
          'success': false,
          'message': data['message']?.toString() ??
              'Failed to submit reservation (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

Future<List<PcSession>> fetchMySessions() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) return [];

final profileRes = await authService.getProfile();
    final String currentUserId = profileRes['data']?['id']?.toString() ??
        profileRes['data']?['_id']?.toString() ??
        profileRes['data']?['studentId']?.toString() ??
        '';

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/computers/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['sessions'] ?? []);

        final allSessions = list
            .map((e) => PcSession.fromJson(e as Map<String, dynamic>))
            .toList();

final result = currentUserId.isNotEmpty
            ? allSessions.where((s) => s.userId == currentUserId).toList()
            : <PcSession>[];

        if (result.isNotEmpty) {
          _saveSessionsToCache(result);
        }

        return result;
      }
      return await getPersistentCachedSessions();
    } catch (e) {
      return await getPersistentCachedSessions();
    }
  }
}
