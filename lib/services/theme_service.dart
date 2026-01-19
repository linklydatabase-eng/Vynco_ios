import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isDarkMode = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final darkMode = prefs.getBool('dark_mode') ?? true; // Default to dark mode
      _isDarkMode = darkMode;
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDark);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  ThemeData get currentTheme {
    return _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }
}
