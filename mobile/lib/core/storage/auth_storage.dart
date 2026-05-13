import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Secure storage operations can hang on emulators due to Android Keystore
// initialization. We time-box every call and fall back to SharedPreferences.
class AuthStorage {
  static const _timeout = Duration(seconds: 3);

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyBiometric = 'biometric_enabled';
  static const _prefKeyToken = 'pref_auth_token';
  static const _prefKeyUserId = 'pref_user_id';

  static Future<String?> _secureRead(String key, String prefKey) async {
    try {
      return await _secure.read(key: key).timeout(_timeout);
    } catch (_) {
      // Secure storage hung or failed → fall back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefKey);
    }
  }

  static Future<void> _secureWrite(String key, String prefKey, String value) async {
    try {
      await _secure.write(key: key, value: value).timeout(_timeout);
    } catch (_) {
      // ignore
    }
    // Also write to SharedPreferences as fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, value);
  }

  static Future<void> saveToken(String token) =>
      _secureWrite(_keyToken, _prefKeyToken, token);

  static Future<String?> getToken() =>
      _secureRead(_keyToken, _prefKeyToken);

  static Future<void> deleteToken() async {
    try {
      await _secure.delete(key: _keyToken).timeout(_timeout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyToken);
  }

  static Future<void> saveUserId(String id) =>
      _secureWrite(_keyUserId, _prefKeyUserId, id);

  static Future<String?> getUserId() =>
      _secureRead(_keyUserId, _prefKeyUserId);

  static Future<bool> isBiometricEnabled() async {
    try {
      final val = await _secure.read(key: _keyBiometric).timeout(_timeout);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secure.write(key: _keyBiometric, value: enabled.toString())
          .timeout(_timeout);
    } catch (_) {}
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    try {
      await _secure.deleteAll().timeout(_timeout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyToken);
    await prefs.remove(_prefKeyUserId);
  }
}
