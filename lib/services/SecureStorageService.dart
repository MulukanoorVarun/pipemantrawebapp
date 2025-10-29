import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Private constructor
  SecureStorageService._privateConstructor();

  // Singleton instance
  static final SecureStorageService _instance =
      SecureStorageService._privateConstructor();

  // Public getter to access the singleton
  static SecureStorageService get instance => _instance;

  // SecureStorage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ----------- Set Methods -----------

  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> setInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<void> setDouble(String key, double value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<void> setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  // ----------- Get Methods -----------

  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  Future<int?> getInt(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  Future<double?> getDouble(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? double.tryParse(value) : null;
  }

  Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: key);
    if (value == 'true') return true;
    if (value == 'false') return false;
    return null;
  }

  // ----------- Delete Methods -----------

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ----------- Read All Keys (Optional Debug) -----------

  Future<Map<String, String>> getAllValues() async {
    return await _storage.readAll();
  }
}
