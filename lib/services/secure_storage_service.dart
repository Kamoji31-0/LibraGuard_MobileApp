import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyToken = 'auth_token';

Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
