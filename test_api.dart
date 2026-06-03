import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://libraguard-api.onrender.com/api';

final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'camesa.erasga31@gmail.com',
      'password': 'user123456',
    }),
  );

  if (loginRes.statusCode != 200) {
    print('Login failed: ${loginRes.body}');
    return;
  }

  final token = jsonDecode(loginRes.body)['token'];
  print('Logged in successfully.');

final profileRes = await http.get(
    Uri.parse('$baseUrl/users/profile'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('Profile Response:');
  print(profileRes.body);

final favRes = await http.get(
    Uri.parse('$baseUrl/users/favorites'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('Favorites Endpoint Response (${favRes.statusCode}):');
  print(favRes.body);
}
