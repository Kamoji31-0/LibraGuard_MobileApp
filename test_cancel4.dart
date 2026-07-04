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
  final headers = {'Authorization': 'Bearer $adminToken', 'Content-Type': 'application/json'};
  final body = jsonEncode({'status': 'Cancelled'});

  // Test empty/wrong IDs
  for (final id in ['', 'nonexistent-id', '00000000-0000-0000-0000-000000000000']) {
    final patchRes = await http.patch(Uri.parse('$baseUrl/transactions/$id'), headers: headers, body: body);
    print('PATCH /transactions/$id => ${patchRes.statusCode}');
  }

  // Check POST response structure for new transaction
  // Get users
  final usersRes = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
  print('\nUsers: ${usersRes.statusCode}');
  
  // Get pending sessions
  final sessRes = await http.get(Uri.parse('$baseUrl/computers/sessions'), headers: headers);
  final sessBody = jsonDecode(sessRes.body);
  final List sessList = sessBody is List ? sessBody : (sessBody['data'] ?? sessBody['sessions'] ?? []);
  final pending = sessList.where((s) => s['status']?.toString().toLowerCase().contains('pending') == true).toList();
  print('Pending sessions: ${pending.length}');
  for (final s in pending) {
    print('  id=${s['id']}, keys=${s.keys.toList()}');
    final patchRes = await http.patch(
      Uri.parse('$baseUrl/computers/sessions/${s['id']}'),
      headers: headers,
      body: body,
    );
    print('  PATCH => ${patchRes.statusCode}');
  }

  // Test what POST /transactions returns
  final booksRes = await http.get(Uri.parse('$baseUrl/books'), headers: headers);
  final booksBody = jsonDecode(booksRes.body);
  final List books = booksBody is List ? booksBody : (booksBody['data'] ?? []);
  if (books.isNotEmpty) {
    final bookId = books.first['id'];
    // Find a student user
    final usersBody = jsonDecode(usersRes.body);
    final List users = usersBody is List ? usersBody : (usersBody['data'] ?? []);
    final student = users.firstWhere(
      (u) => u['role']?.toString().toLowerCase() == 'student' || u['role']?.toString().toLowerCase() == 'user',
      orElse: () => users.first,
    );
    final userId = student['id'];
    print('\nCreating tx for userId=$userId bookId=$bookId');
    final createRes = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: headers,
      body: jsonEncode({'userId': userId, 'bookId': bookId, 'dueDate': DateTime.now().add(Duration(days: 7)).toIso8601String()}),
    );
    print('POST /transactions => ${createRes.statusCode}');
    print('Body: ${createRes.body.substring(0, createRes.body.length.clamp(0, 500))}');
    if (createRes.statusCode == 200 || createRes.statusCode == 201) {
      final created = jsonDecode(createRes.body);
      final tx = created is Map && created['data'] != null ? created['data'] : created;
      print('Created tx id=${tx['id']}, keys=${tx is Map ? tx.keys.toList() : 'not map'}');
    }
  }
}
