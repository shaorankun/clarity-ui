import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey    = 'user_info';
  static const _roomKey = 'current_room_id';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey,  value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final str = await _storage.read(key: _userKey);
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<String?> getAccessToken()  async => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() async => _storage.read(key: _refreshKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }

  // Generic key-value helpers cho các feature khác (e.g. TimerProvider)
  static Future<String?> readRaw(String key)               async => _storage.read(key: key);
  static Future<void>    writeRaw(String key, String value) async => _storage.write(key: key, value: value);

  static Future<void> saveRoomId(String roomId) async {
    await _storage.write(key: _roomKey, value: roomId);
  }

  static Future<String?> getRoomId() async =>
      _storage.read(key: _roomKey);

  static Future<void> clearRoomId() async =>
      _storage.delete(key: _roomKey);
}