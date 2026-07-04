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

  final txRes = await http.get(
    Uri.parse('$baseUrl/transactions'),
    headers: {'Authorization': 'Bearer $adminToken', 'Content-Type': 'application/json'},
  );
  final txBody = jsonDecode(txRes.body);
  final List txList = txBody is List ? txBody : (txBody['data'] ?? txBody['transactions'] ?? []);
  final pending = txList.where((t) => t['status']?.toString().toLowerCase().contains('pending') == true).toList();
  if (pending.isEmpty) {
    print('No pending transactions');
    return;
  }
  final txId = pending.first['id'];
  print('Testing cancel for txId=$txId');

  final headers = {
    'Authorization': 'Bearer $adminToken',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode({'status': 'Cancelled'});

  for (final method in ['PATCH', 'PUT', 'DELETE', 'POST']) {
    final uri = Uri.parse('$baseUrl/transactions/$txId');
    http.Response res;
    switch (method) {
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: body);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: body);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        res = await http.post(uri, headers: headers, body: body);
    }
    print('$method /transactions/$txId => ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
  }

  // Try dedicated cancel routes
  final cancelRoutes = [
    '$baseUrl/transactions/$txId/cancel',
    '$baseUrl/transactions/cancel/$txId',
    '$baseUrl/transactions/cancel',
  ];
  for (final route in cancelRoutes) {
    final res = await http.post(Uri.parse(route), headers: headers, body: body);
    print('POST $route => ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
  }

  // PC sessions
  final sessRes = await http.get(
    Uri.parse('$baseUrl/computers/sessions'),
    headers: headers,
  );
  print('\nSessions status: ${sessRes.statusCode}');
  if (sessRes.statusCode == 200) {
    final sessBody = jsonDecode(sessRes.body);
    final List sessList = sessBody is List ? sessBody : (sessBody['data'] ?? sessBody['sessions'] ?? []);
    print('Session count: ${sessList.length}');
    if (sessList.isNotEmpty) {
      final sess = sessList.firstWhere(
        (s) => s['status']?.toString().toLowerCase().contains('pending') == true,
        orElse: () => sessList.first,
      );
      final sessId = sess['id'];
      print('Testing cancel for sessionId=$sessId status=${sess['status']}');
      for (final method in ['PATCH', 'PUT', 'DELETE']) {
        final uri = Uri.parse('$baseUrl/computers/sessions/$sessId');
        http.Response res;
        switch (method) {
          case 'PATCH':
            res = await http.patch(uri, headers: headers, body: body);
            break;
          case 'PUT':
            res = await http.put(uri, headers: headers, body: body);
            break;
          default:
            res = await http.delete(uri, headers: headers);
        }
        print('$method /computers/sessions/$sessId => ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
      }
      for (final route in [
        '$baseUrl/computers/sessions/$sessId/cancel',
        '$baseUrl/computers/sessions/cancel/$sessId',
      ]) {
        final res = await http.post(Uri.parse(route), headers: headers, body: body);
        print('POST $route => ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
      }
    }
  }
}
