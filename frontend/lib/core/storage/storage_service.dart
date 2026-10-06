import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError(),
);

class StorageService {
  final SharedPreferences _prefs;
  StorageService(this._prefs);

  SharedPreferences get prefs => _prefs;

  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _baseUrlKey = 'backend_base_url';

  // Default backend URL deployed on Render
  static const String defaultBaseUrl = 'https://itlab-2.onrender.com';

  Future<void> saveToken(String token) async =>
      await _prefs.setString(_tokenKey, token);
  String? getToken() => _prefs.getString(_tokenKey);
  Future<void> clearToken() async => await _prefs.remove(_tokenKey);

  Future<void> saveRole(String role) async =>
      await _prefs.setString(_roleKey, role);
  String? getRole() => _prefs.getString(_roleKey);
  Future<void> clearRole() async => await _prefs.remove(_roleKey);

  Future<void> saveUserData({required String id, required String email}) async {
    await _prefs.setString(_userIdKey, id);
    await _prefs.setString(_userEmailKey, email);
  }

  String? getUserId() => _prefs.getString(_userIdKey);
  String? getUserEmail() => _prefs.getString(_userEmailKey);

  Future<void> saveBaseUrl(String url) async =>
      await _prefs.setString(_baseUrlKey, url.trim());
  String getBaseUrl() => _prefs.getString(_baseUrlKey) ?? defaultBaseUrl;

  Future<void> clearAll() async {
    final currentBaseUrl = getBaseUrl();
    await _prefs.clear();
    await saveBaseUrl(currentBaseUrl);
  }
}
