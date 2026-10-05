import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService(this._prefs)
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  // Initialize helper to load base URL overrides
  void loadConfigOverrides() {
    final overrideUrl = _prefs.getString(AppConfig.keyBaseUrlOverride);
    if (overrideUrl != null && overrideUrl.isNotEmpty) {
      AppConfig.baseUrl = overrideUrl;
    }
  }

  // Set & Get custom API URL
  Future<void> saveBaseUrlOverride(String url) async {
    await _prefs.setString(AppConfig.keyBaseUrlOverride, url);
    AppConfig.baseUrl = url;
  }

  Future<void> clearBaseUrlOverride() async {
    await _prefs.remove(AppConfig.keyBaseUrlOverride);
    AppConfig.baseUrl = AppConfig.defaultBaseUrl;
  }

  String getBaseUrl() {
    return AppConfig.baseUrl;
  }

  // Theme settings (0 = system, 1 = light, 2 = dark)
  int getThemeMode() {
    return _prefs.getInt(AppConfig.keyThemeMode) ?? 0;
  }

  Future<void> saveThemeMode(int mode) async {
    await _prefs.setInt(AppConfig.keyThemeMode, mode);
  }

  // Admin Auth Token (secure storage)
  Future<void> saveAdminToken(String token) async {
    await _secureStorage.write(key: AppConfig.keyAdminToken, value: token);
  }

  Future<String?> getAdminToken() async {
    return await _secureStorage.read(key: AppConfig.keyAdminToken);
  }

  Future<void> deleteAdminToken() async {
    await _secureStorage.delete(key: AppConfig.keyAdminToken);
  }

  // Generic key-value store helper for JSON cache
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
