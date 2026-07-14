import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF8B6842);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: const Color(0xFFF7F0E8),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF4EBDD),
    fontFamily: 'Georgia',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF3C2F26)),
      titleTextStyle: TextStyle(
        color: Color(0xFF30261F),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Georgia',
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontFamily: 'Georgia'),
      bodyMedium: TextStyle(fontFamily: 'Georgia'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF7F0E8),
      selectedItemColor: Color(0xFF8B6842),
      unselectedItemColor: Color(0xFF8F7B6B),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF9F4ED),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}