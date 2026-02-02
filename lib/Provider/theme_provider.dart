import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: const Color(0xFF2563EB),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF64B5F6),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardColor: Colors.white,
    dividerColor: Color(0xFFE2E8F0),
    iconTheme: const IconThemeData(color: Color(0xFF64748B)),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: const Color(0xFF3B82F6),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF60A5FA),
      surface: Color(0xFF1E293B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardColor: const Color(0xFF1E293B),
    dividerColor: Color(0xFF334155),
    iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
  );
}

/// Helper class to get theme-aware colors
class AppColors {
  final BuildContext context;

  AppColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Primary colors
  Color get primary => Theme.of(context).primaryColor;

  // Background colors
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get card => Theme.of(context).cardColor;
  Color get surface => Theme.of(context).colorScheme.surface;

  // Text colors
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textHint =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Border/Divider colors
  Color get border =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get divider => Theme.of(context).dividerColor;

  // Input field colors
  Color get inputFill => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get inputBorder =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // Icon colors
  Color get icon => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get iconActive =>
      isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

  // Status colors (same for both themes)
  Color get success => const Color(0xFF22C55E);
  Color get error => const Color(0xFFEF4444);
  Color get warning => const Color(0xFFF59E0B);
  Color get info => const Color(0xFF3B82F6);
}
