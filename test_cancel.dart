import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://libraguard-api.onrender.com/api';

  // First try admin to get a real transaction ID
  final adminLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'admin@libraguard.edu', 'password': 'admin123'}),
  );
  final adminToken = jsonDecode(adminLoginRes.body)['token'];
  
  // Get all transactions as admin
  final txRes = await http.get(
    Uri.parse('$baseUrl/transactions'),
    headers: {'Authorization': 'Bearer $adminToken', 'Content-Type': 'application/json'},
  );
  final txBody = jsonDecode(txRes.body);
  final List txList = txBody is List ? txBody : (txBody['data'] ?? txBody['transactions'] ?? []);

  // Find a PENDING transaction
  final pending = txList.where((t) => t['status']?.toString().toLowerCase().contains('pending') == true).toList();
  print('All pending transactions: ${pending.length}');
  if (pending.isNotEmpty) {
    final tx = pending.first;
    print('Pending TX: id=${tx['id']}, userId=${tx['userId']}, studentId=${tx['studentId']}');
    print('All keys: ${tx.keys.toList()}');
  }

  // Print first 3 transactions with status
  for (final tx in txList.take(5)) {
    print('TX id=${tx['id']}, status=${tx['status']}, userId=${tx['userId']}, studentId=${tx['studentId']}');
  }
  
  // Now test what routes are available
  print('\n--- Testing route availability ---');
  
  // Try GET /transactions to see available routes
  final routeRes = await http.get(
    Uri.parse('$baseUrl/transactions/cancel'),
    headers: {'Authorization': 'Bearer $adminToken'},
  );
  print('GET /transactions/cancel: ${routeRes.statusCode}');
  print('Body: ${routeRes.body.substring(0, routeRes.body.length.clamp(0, 300))}');
}
