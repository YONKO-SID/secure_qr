import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const String _themeBoxName = 'theme_box';
  static const String _themeKey = 'is_dark_theme';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<bool>(_themeBoxName);
  }
  
  static bool get isDarkTheme {
    final box = Hive.box<bool>(_themeBoxName);
    return box.get(_themeKey, defaultValue: false)!;
  }
  
  static Future<void> setDarkTheme(bool isDark) async {
    final box = Hive.box<bool>(_themeBoxName);
    await box.put(_themeKey, isDark);
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      dividerColor: Colors.grey[300],
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue[700],
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[850],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.grey[600],
    );
  }
  
  static ThemeData getTheme(bool isDark) {
    return isDark ? darkTheme : lightTheme;
  }
}