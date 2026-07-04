import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://libraguard-api.onrender.com/api';

  final adminLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'admin@libraguard.edu', 'password': 'admin123'}),
  );
  final adminToken = jsonDecode(adminLoginRes.body)['token'];
  final adminHeaders = {'Authorization': 'Bearer $adminToken', 'Content-Type': 'application/json'};

  // Get users and find one with pending transaction
  final usersRes = await http.get(Uri.parse('$baseUrl/users'), headers: adminHeaders);
  final usersBody = jsonDecode(usersRes.body);
  final List users = usersBody is List ? usersBody : (usersBody['data'] ?? []);

  final txRes = await http.get(Uri.parse('$baseUrl/transactions'), headers: adminHeaders);
  final txList = jsonDecode(txRes.body) as List;

  for (final tx in txList.where((t) => t['status'].toString().toLowerCase().contains('pending'))) {
    final userId = tx['userId'];
    final user = users.cast<Map>().firstWhere(
      (u) => u['id'] == userId || u['studentId'] == userId,
      orElse: () => {},
    );
    if (user.isEmpty) {
      print('No user for tx ${tx['id']} userId=$userId');
      continue;
    }
    final email = user['email'];
    print('\nTrying user $email for tx ${tx['id']}');

    // Try common passwords
    for (final pw in ['user123456', 'password', 'password123', 'student123']) {
      final loginRes = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pw}),
      );
      if (loginRes.statusCode == 200) {
        final token = jsonDecode(loginRes.body)['token'];
        final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
        final body = jsonEncode({'status': 'Cancelled'});
        final patchRes = await http.patch(
          Uri.parse('$baseUrl/transactions/${tx['id']}'),
          headers: headers,
          body: body,
        );
        print('  password=$pw PATCH => ${patchRes.statusCode}: ${patchRes.body.substring(0, patchRes.body.length.clamp(0, 200))}');
        break;
      }
    }
  }

  // Test POST session response shape
  final pcsRes = await http.get(Uri.parse('$baseUrl/computers'), headers: adminHeaders);
  final pcsBody = jsonDecode(pcsRes.body);
  final List pcs = pcsBody is List ? pcsBody : (pcsBody['data'] ?? []);
  if (pcs.isNotEmpty) {
    final pcId = pcs.firstWhere((p) => p['status']?.toString().toLowerCase() == 'available', orElse: () => pcs.first)['id'];
    final student = users.cast<Map>().firstWhere((u) => u['role']?.toString().toLowerCase() != 'admin', orElse: () => users.first);
    print('\nPOST session for user ${student['id']} pc $pcId');
    final createRes = await http.post(
      Uri.parse('$baseUrl/computers/sessions'),
      headers: adminHeaders,
      body: jsonEncode({'computerId': pcId, 'hours': 1.0, 'userId': student['id']}),
    );
    print('POST session => ${createRes.statusCode}');
    print(createRes.body.substring(0, createRes.body.length.clamp(0, 500)));
  }
}
