
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  static Future<String?> getAccessToken() async => await _storage.read(key: 'accessToken');

  static Future<void> clearAll() async => await _storage.deleteAll();
}