import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://libraguard-api.onrender.com/api';

  final SecureStorageService _secureStorage = SecureStorageService();

  Future<void> saveToken(String token) async {
    print('DEBUG: Attempting to save token: ${token.substring(0, 10)}...');
    await _secureStorage.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    print('DEBUG: Token saved successfully to both storage layers');
  }

  Future<String?> getToken() async {
    try {
      String? token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        print('DEBUG: Token found in SecureStorage');
        return token;
      }
    } catch (e) {
      print('DEBUG: SecureStorage error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      print('DEBUG: Token found in SharedPreferences');

      await _secureStorage.saveToken(token);
    } else {
      print('DEBUG: No token found in SharedPreferences either');
    }
    return token;
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('jwt_token');
    await prefs.remove('first_name');
    await prefs.remove('user_profile');

    await prefs.remove('2fa_enabled');
    await prefs.remove('cached_2fa_setup');

    await prefs.remove('cached_gate_logs');
    await prefs.remove('cached_pc_sessions');
    await prefs.remove('cached_pc_list');
    await prefs.remove('cached_transactions_list');
  }

  Future<void> saveFirstName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', name);
  }

  Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('first_name');
  }

  Future<void> saveProfile(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  Future<void> saveThemePreference(String email, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();
    await prefs.setString('themeMode_$normalizedEmail', mode);

    await prefs.setBool('isDarkTheme_$normalizedEmail', mode == 'dark');

    await prefs.setString('app_theme_mode', mode);
  }

  Future<String> getThemePreference(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();

    final mode = prefs.getString('themeMode_$normalizedEmail');
    if (mode != null) return mode;

    final isDark = prefs.getBool('isDarkTheme_$normalizedEmail');
    if (isDark != null) {
      return isDark ? 'dark' : 'light';
    }

    return prefs.getString('app_theme_mode') ?? 'system';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final String msg = data['message']?.toString().toLowerCase() ?? '';
        final bool msgMentions2FA = msg.contains('2fa') ||
            msg.contains('mfa') ||
            msg.contains('verification') ||
            msg.contains('two-factor') ||
            msg.contains('two factor') ||
            msg.contains('challenge');

        final bool serverRequires2FA = data['require2fa'] == true ||
            data['requires2FA'] == true ||
            data['twoFactorRequired'] == true ||
            data['mfa_required'] == true ||
            data['status'] == '2fa_required' ||
            msgMentions2FA ||
            (data['user'] != null && data['user']['is2faEnabled'] == true);

        if (serverRequires2FA) {
          await set2FAEnabled(true);
          return {
            'success': true,
            'require2fa': true,
            'tempToken': data['tempToken'],
            'data': data
          };
        }

        final String? token = data['token'] ??
            data['accessToken'] ??
            data['data']?['token'] ??
            data['user']?['token'];

        if (token != null) {
          await saveToken(token);

          await _applyPendingStudentFields(token);
        }

        final user = data['user'] ?? data['data'] ?? data;
        await saveProfile(user);

        final fullName =
            (user['name'] ?? user['fullName'] ?? '').toString().trim();
        if (fullName.isNotEmpty) {
          final firstName = fullName.split(' ').first;
          await saveFirstName(firstName);
        }
        return {'success': true, 'data': data};
      } else {
        final String msg = data['message']?.toString().toLowerCase() ?? '';
        final bool is2FARelated = msg.contains('2fa') ||
            msg.contains('mfa') ||
            msg.contains('verification') ||
            msg.contains('two-factor') ||
            msg.contains('two factor') ||
            msg.contains('challenge');

        if ((response.statusCode == 401 ||
                response.statusCode == 403 ||
                response.statusCode == 422) &&
            is2FARelated) {
          await set2FAEnabled(true);
          return {'success': true, 'require2fa': true, 'data': data};
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> _applyPendingStudentFields(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingDept = prefs.getString('pending_dept');
    final pendingYear = prefs.getString('pending_year');
    if (pendingDept == null && pendingYear == null) return;

    try {
      final body = <String, dynamic>{};
      if (pendingDept != null) body['dept'] = pendingDept;
      if (pendingYear != null) {
        body['year'] = pendingYear;
        body['yearLevel'] = pendingYear;
      }

      http.Response? res;
      for (final method in ['PATCH', 'PUT']) {
        final uri = Uri.parse('$baseUrl/users/profile');
        res = method == 'PATCH'
            ? await http.patch(uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(body))
            : await http.put(uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(body));
        if (res.statusCode == 200) break;
      }
    } catch (_) {}
    await prefs.remove('pending_dept');
    await prefs.remove('pending_year');
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String idNumber,
    String? department,
    String? yearLevel,
    String? accessCode,
    String role = 'Student',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'idNumber': idNumber,
          'role': role,
          if (department != null && department.isNotEmpty) 'dept': department,
          if (yearLevel != null && yearLevel.isNotEmpty) ...{
            'year': yearLevel,
            'yearLevel': yearLevel,
          },
          if (accessCode != null && accessCode.isNotEmpty)
            'accessCode': accessCode,
        }),
      );
      print(
          'DEBUG AUTH: register body sent → dept=$department, year=$yearLevel, status=${response.statusCode}');
      print('DEBUG AUTH: register response → ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final deptVal = department?.trim() ?? '';
        final yearVal = yearLevel?.trim() ?? '';
        if (role.toUpperCase() == 'STUDENT' &&
            (deptVal.isNotEmpty || yearVal.isNotEmpty)) {
          final prefs = await SharedPreferences.getInstance();
          if (deptVal.isNotEmpty)
            await prefs.setString('pending_dept', deptVal);
          if (yearVal.isNotEmpty)
            await prefs.setString('pending_year', yearVal);
        }

        final token =
            data['token'] ?? data['data']?['token'] ?? data['user']?['token'];
        if (token != null) await _applyPendingStudentFields(token);

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset link sent to $email'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send reset link'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      {required String resetToken, required String newPassword}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': resetToken,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully!'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null) {
      final cached = await getCachedProfile();
      if (cached != null) return {'success': true, 'data': cached};
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['user'] ?? data['data'] ?? data;
        await saveProfile(user);
        return {'success': true, 'data': user};
      } else {
        final cached = await getCachedProfile();
        if (cached != null) return {'success': true, 'data': cached};
        return {'success': false, 'message': 'Failed to fetch profile'};
      }
    } catch (e) {
      final cached = await getCachedProfile();
      if (cached != null) return {'success': true, 'data': cached};
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSecurity(
      String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'Not authenticated'};

      final response = await http.put(
        Uri.parse('$baseUrl/users/security'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<dynamic>> getTransactions() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getComputerSessions() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/computers/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static const String _gateLogsCacheKey = 'cached_gate_logs';

  Future<void> _saveGateLogsToCache(List<dynamic> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gateLogsCacheKey, jsonEncode(logs));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedGateLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_gateLogsCacheKey);
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getGateLogs() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final profileRes = await getProfile();
      final String currentUserId = profileRes['data']?['id']?.toString() ??
          profileRes['data']?['_id']?.toString() ??
          profileRes['data']?['studentId']?.toString() ??
          '';

      final response = await http.get(
        Uri.parse('$baseUrl/rfid/my-logs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['logs'] ?? []);

        final filteredList = currentUserId.isNotEmpty
            ? list.where((log) {
                final logMap = log is Map ? log : {};
                final logUid = (logMap['userId'] ??
                        logMap['studentId'] ??
                        logMap['user']?['id'] ??
                        logMap['user']?['_id'])
                    ?.toString();
                return logUid == currentUserId;
              }).toList()
            : [];

        final results = filteredList.map((log) {
          final logMap = Map<String, dynamic>.from(log as Map);
          final timeIn = logMap['timeIn']?.toString() ?? '';
          final timeOut = logMap['timeOut']?.toString() ?? 'Active';
          final lane = logMap['lane']?.toString() ?? 'N/A';
          final date = logMap['date']?.toString() ?? '';

          return <String, dynamic>{
            ...logMap,
            'action': 'Gate entry/exit (Lane $lane)',
            'createdAt': date.isNotEmpty ? date : timeIn,
            'status': timeOut == 'null' ||
                    timeOut.isEmpty ||
                    logMap['timeOut'] == null
                ? 'Active'
                : 'Completed',
          };
        }).toList();

        _saveGateLogsToCache(results);

        return results;
      }

      return await getCachedGateLogs();
    } catch (e) {
      return await getCachedGateLogs();
    }
  }

  Future<Map<String, dynamic>> getLibraryOccupancy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rfid/occupancy'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'count': data['count'] ?? 0,
          'maxCapacity': 100,
        };
      }
    } catch (_) {}

    return {'count': 0, 'maxCapacity': 100};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String idNumber,
    required String contact,
    required String gender,
    String? dept,
    String? year,
    String? imageBase64,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    try {
      final body = {
        'name': name,
        'idNumber': idNumber,
        'contact': contact,
        'gender': gender,
      };
      if (dept != null) body['dept'] = dept;
      if (year != null) body['year'] = year;
      if (imageBase64 != null) {
        body['image'] = imageBase64;
      }

      print('DEBUG: Profile Update Token: Bearer ${token.substring(0, 15)}...');
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer ${token.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = (data is Map && data['user'] != null)
            ? data['user']
            : (data is Map && data['data'] != null)
                ? data['data']
                : data;
        await saveProfile(user);
        return {'success': true, 'data': user};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static const String _2faEnabledKey = '2fa_enabled';

  Future<bool> is2FAEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    final localFlag = prefs.getBool(_2faEnabledKey);
    if (localFlag != null) {
      return localFlag;
    }

    final profile = await getCachedProfile();
    if (profile != null) {
      final enabled = profile['twoFactorEnabled'] == true ||
          profile['is2faEnabled'] == true ||
          profile['isTwoFactorEnabled'] == true;

      await set2FAEnabled(enabled);
      return enabled;
    }

    return false;
  }

  Future<void> set2FAEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_2faEnabledKey, enabled);
  }

  Future<Map<String, dynamic>> get2FASetup() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_2fa_setup');
    if (cached != null) {
      return jsonDecode(cached);
    }

    final token = await getToken();
    if (token == null)
      return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/2fa/setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final setup = {
          'qrCodeUrl': data['qrCodeUrl'] ?? data['qr_code_url'],
          'manualKey': data['manualKey'] ?? data['manual_key'],
          'secret': data['secret'],
          'otpauthUri': data['otpauthUri'] ?? data['otpauth_url'],
        };
        await prefs.setString('cached_2fa_setup', jsonEncode(setup));
        return setup;
      }
      return {'success': false, 'message': 'Failed to fetch 2FA setup'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> clear2FACache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_2fa_setup');
  }

  Future<Map<String, dynamic>> enable2FA(String code, String secret) async {
    final token = await getToken();
    if (token == null)
      return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/enable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'secret': secret,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await set2FAEnabled(true);

        await getProfile();
        return {
          'success': true,
          'message': data['message'] ??
              'Two-Factor Authentication enabled successfully!'
        };
      }
      return {
        'success': false,
        'message':
            data['message'] ?? 'Invalid verification code. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> disable2FA(String password, String code) async {
    final token = await getToken();
    if (token == null)
      return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/disable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'password': password,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await set2FAEnabled(false);

        await getProfile();
        return {
          'success': true,
          'message': data['message'] ?? 'Two-Factor Authentication disabled.'
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Invalid password or verification code.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<int> getNotificationCount() async {
    final enabled = await is2FAEnabled();
    return enabled ? 0 : 1;
  }

  Future<Map<String, dynamic>> verify2FALogin(
      String code, String? tempToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/2fa/verify'),
        headers: {
          'Content-Type': 'application/json',
          if (tempToken != null) 'Authorization': 'Bearer $tempToken',
        },
        body: jsonEncode({
          'code': code,
          if (tempToken != null) 'tempToken': tempToken,
        }),
      );

      final data = jsonDecode(response.body);

      print('DEBUG: 2FA Status: ${response.statusCode}');
      print('DEBUG: 2FA Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String? token = data['token'] ??
            data['accessToken'] ??
            data['jwt'] ??
            data['authToken'] ??
            data['access_token'] ??
            data['data']?['token'] ??
            data['user']?['token'];

        if (token == null) {
          print('DEBUG: Greedy scanning for JWT...');
          data.forEach((key, value) {
            if (value is String &&
                value.trim().startsWith('ey') &&
                value.trim().split('.').length == 3) {
              token = value.trim();
              print('DEBUG: Greedily found token in key: $key');
            }
          });

          if (token == null && data['data'] is Map) {
            (data['data'] as Map).forEach((key, value) {
              if (value is String &&
                  value.trim().startsWith('ey') &&
                  value.trim().split('.').length == 3) {
                token = value.trim();
                print('DEBUG: Greedily found token in data.$key');
              }
            });
          }
        }

        if (token != null) {
          await saveToken(token!);
        } else if (tempToken != null) {
          print(
              'DEBUG: No new token in 2FA response. Saving tempToken as session token.');
          await saveToken(tempToken);
        } else {
          print('DEBUG: WARNING - No token found anywhere. Update will fail.');
        }
        final user = data['user'] ?? data['data'] ?? data;
        await saveProfile(user);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
