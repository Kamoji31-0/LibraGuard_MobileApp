import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// A single computer from the library lab.
class LibraryComputer {
  final String id;
  final String name;
  final String status; // "Available", "In Use"

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

/// A single PC reservation / session record.
class PcSession {
  final String id;
  final String userId;
  final String computerId;
  final String computerName;
  final String status; // Pending, Active, Completed
  final String duration; // e.g. "1 Hour 0 Minutes"
  final String? startTime;
  final String? endTime;
  final String? createdAt;

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

    // Duration: handle int (minutes) or string
    String dur = 'N/A';
    final rawDur = json['duration'] ?? json['requestedDuration'];
    if (rawDur != null) {
      if (rawDur is int) {
        final h = rawDur ~/ 60;
        final m = rawDur % 60;
        dur = h > 0 ? '$h Hour${h > 1 ? 's' : ''} $m Min' : '$m Min';
      } else {
        dur = rawDur.toString();
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
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class PcService {
  static const String _baseUrl = 'https://libraguard-api.onrender.com/api';

  /// Fetch all library computers with their availability.
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
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['computers'] ?? []);
        return list
            .map((e) => LibraryComputer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Submit a PC reservation.
  ///
  /// [computerId] — the UUID of the chosen computer.
  /// [durationMinutes] — requested session length in minutes (60, 120, 180).
  Future<Map<String, dynamic>> submitReservation({
    required String computerId,
    required int durationMinutes,
  }) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'You are not logged in.'};
    }

    // Get userId from cached profile
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

  /// Fetch the current user's PC session history.
  Future<List<PcSession>> fetchMySessions() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) return [];

    // Safety constraint: strictly enforce the active userId
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
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['sessions'] ?? []);
            
        final allSessions = list
            .map((e) => PcSession.fromJson(e as Map<String, dynamic>))
            .toList();

        // Enforce user-specific filtering down to the ID level rigidly, fallback to empty list instead of global scope.
        if (currentUserId.isNotEmpty) {
          return allSessions.where((s) => s.userId == currentUserId).toList();
        }
        
        return []; // RIGID FALLBACK: IF NO ACTIVE USER, SHOW NOTHING!
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
