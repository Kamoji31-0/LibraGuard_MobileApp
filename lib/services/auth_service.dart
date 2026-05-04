import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://libraguard-api.onrender.com/api';

  final SecureStorageService _secureStorage = SecureStorageService();

  // Save JWT token
  Future<void> saveToken(String token) async {
    await _secureStorage.saveToken(token);
    // Optional: Keep in SharedPreferences for legacy if needed, 
    // but better to move entirely to secure storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get JWT token
  Future<String?> getToken() async {
    // Try secure storage first
    String? token = await _secureStorage.getToken();
    if (token != null) return token;

    // Fallback to SharedPreferences (migration path)
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
    if (token != null) {
      // Migrate to secure storage
      await _secureStorage.saveToken(token);
    }
    return token;
  }

  // Clear session
  Future<void> logout() async {
    await _secureStorage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('first_name');
    await prefs.remove('user_profile');
  }

  // Save first name
  Future<void> saveFirstName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', name);
  }

  // Get first name
  Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('first_name');
  }

  // Save profile
  Future<void> saveProfile(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user));
  }

  // Get cached profile
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // Save theme preference for a specific email
  // mode: 'light', 'dark', or 'system'
  Future<void> saveThemePreference(String email, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();
    await prefs.setString('themeMode_$normalizedEmail', mode);
    // Legacy support: sync the boolean flag for components that still check it
    await prefs.setBool('isDarkTheme_$normalizedEmail', mode == 'dark');
    // Global fallback for startup (before email is known)
    await prefs.setString('app_theme_mode', mode);
  }

  // Get theme preference for a specific email
  Future<String> getThemePreference(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Try new string-based preference
    final mode = prefs.getString('themeMode_$normalizedEmail');
    if (mode != null) return mode;

    // 2. Fallback to legacy boolean preference
    final isDark = prefs.getBool('isDarkTheme_$normalizedEmail');
    if (isDark != null) {
      return isDark ? 'dark' : 'light';
    }

    // 3. Global fallback
    return prefs.getString('app_theme_mode') ?? 'system';
  }

  // Login
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['token'] != null) {
          await saveToken(data['token']);
          // Apply any pending dept/year saved during registration
          await _applyPendingStudentFields(data['token']);
        }
        // Persist first name and full profile
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
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Apply pending dept/year saved during registration (called after login)
  Future<void> _applyPendingStudentFields(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingDept = prefs.getString('pending_dept');
    final pendingYear = prefs.getString('pending_year');
    if (pendingDept == null && pendingYear == null) return;

    try {
      final body = <String, dynamic>{};
      if (pendingDept != null) body['dept'] = pendingDept;
      if (pendingYear != null) body['year'] = pendingYear;

      // Try PATCH first, then PUT
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
      // Clear pending values regardless of result
    } catch (_) {}
    await prefs.remove('pending_dept');
    await prefs.remove('pending_year');
  }

  // Register
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
          if (yearLevel != null && yearLevel.isNotEmpty) 'year': yearLevel,
          if (accessCode != null && accessCode.isNotEmpty)
            'accessCode': accessCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save dept/year locally — the /auth/register endpoint ignores these,
        // so we flush them to the server on first login via _applyPendingStudentFields
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

        // If the server returns a token immediately, flush now
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

  // Forgot Password
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

  // Reset Password using Code/Token
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

  // Get User Profile — always fetches live, falls back to cache
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    // If no token, fall back to cache (e.g., offline)
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
        // API may return {user: {...}} or the user directly
        final user = data['user'] ?? data['data'] ?? data;
        await saveProfile(user); // update cache
        return {'success': true, 'data': user};
      } else {
        // Network failed — serve stale cache
        final cached = await getCachedProfile();
        if (cached != null) return {'success': true, 'data': cached};
        return {'success': false, 'message': 'Failed to fetch profile'};
      }
    } catch (e) {
      // Offline — serve stale cache
      final cached = await getCachedProfile();
      if (cached != null) return {'success': true, 'data': cached};
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update Security Credentials (Password)
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

  // Get Borrowing Transactions
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

  // Get Computer Sessions
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

  // Get Gate Logs (Synchronized with web system)
  Future<List<dynamic>> getGateLogs() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rfid/my-logs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['logs'] ?? []);

        // Map data to match the UI expectations in profile_screen.dart
        return list.map((log) {
          final timeIn = log['timeIn']?.toString() ?? '';
          final timeOut = log['timeOut']?.toString() ?? 'Active';
          final lane = log['lane']?.toString() ?? 'N/A';
          final date = log['date']?.toString() ?? '';

          return {
            ...log,
            'action': 'Gate entry/exit (Lane $lane)',
            'createdAt': date.isNotEmpty ? date : timeIn,
            'status':
                timeOut == 'null' || timeOut.isEmpty || log['timeOut'] == null
                    ? 'Active'
                    : 'Completed',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get current library occupancy (students currently inside)
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

  // Update User Profile
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

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Normalize: handle {user: {...}} or flat object
        final user = (data is Map && data['user'] != null)
            ? data['user']
            : (data is Map && data['data'] != null)
                ? data['data']
                : data;
        await saveProfile(user); // refresh cache
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
}
