import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final window = WidgetsBinding.instance.window;
      return window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadTheme() {
    final int? themeValue = _prefs.getInt(_themeKey);
    if (themeValue != null) {
      _themeMode = ThemeMode.values[themeValue];
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light || (_themeMode == ThemeMode.system && !isDarkMode)) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    await _prefs.setInt(_themeKey, _themeMode.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }
}
