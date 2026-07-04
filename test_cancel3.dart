import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://libraguard-api.onrender.com/api';

  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'camesa.erasga31@gmail.com', 'password': 'user123456'}),
  );
  print('Login: ${loginRes.statusCode}');
  final token = jsonDecode(loginRes.body)['token'];

  final profileRes = await http.get(
    Uri.parse('$baseUrl/users/profile'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final profile = jsonDecode(profileRes.body);
  final userId = profile['data']?['id'] ?? profile['id'];
  print('User id: $userId');

  final txRes = await http.get(
    Uri.parse('$baseUrl/transactions'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
  );
  final txBody = jsonDecode(txRes.body);
  final List txList = txBody is List ? txBody : (txBody['data'] ?? txBody['transactions'] ?? []);
  print('User transactions: ${txList.length}');
  for (final tx in txList.take(5)) {
    print('  id=${tx['id']}, status=${tx['status']}, userId=${tx['userId']}');
  }

  final pending = txList.where((t) => t['status']?.toString().toLowerCase().contains('pending') == true).toList();
  if (pending.isEmpty) {
    print('No pending tx for user');
  } else {
    final txId = pending.first['id'];
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final body = jsonEncode({'status': 'Cancelled'});
    final patchRes = await http.patch(Uri.parse('$baseUrl/transactions/$txId'), headers: headers, body: body);
    print('User PATCH /transactions/$txId => ${patchRes.statusCode}: ${patchRes.body.substring(0, patchRes.body.length.clamp(0, 300))}');
    final putRes = await http.put(Uri.parse('$baseUrl/transactions/$txId'), headers: headers, body: body);
    print('User PUT /transactions/$txId => ${putRes.statusCode}');
  }

  final sessRes = await http.get(
    Uri.parse('$baseUrl/computers/sessions'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final sessBody = jsonDecode(sessRes.body);
  final List sessList = sessBody is List ? sessBody : (sessBody['data'] ?? sessBody['sessions'] ?? []);
  print('\nAll sessions: ${sessList.length}');
  final userSessions = sessList.where((s) => s['userId'] == userId).toList();
  print('User sessions: ${userSessions.length}');
  for (final s in userSessions.take(5)) {
    print('  id=${s['id']}, status=${s['status']}');
  }
  final pendingSess = userSessions.where((s) => s['status']?.toString().toLowerCase().contains('pending') == true).toList();
  if (pendingSess.isNotEmpty) {
    final sessId = pendingSess.first['id'];
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final body = jsonEncode({'status': 'Cancelled'});
    final patchRes = await http.patch(Uri.parse('$baseUrl/computers/sessions/$sessId'), headers: headers, body: body);
    print('User PATCH /computers/sessions/$sessId => ${patchRes.statusCode}: ${patchRes.body.substring(0, patchRes.body.length.clamp(0, 300))}');
  }
}
