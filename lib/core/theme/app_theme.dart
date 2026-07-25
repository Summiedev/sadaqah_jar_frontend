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
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(color: Color(0xFFE3D7CB), thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFCF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE3D7CB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE3D7CB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: seed, width: 1.5)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF3C2F26),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: Color(0xFF3C2F26)),
      titleTextStyle: TextStyle(
        color: Color(0xFF30261F),
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Georgia',
        height: 1.2,
      ),
      toolbarHeight: 64,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: const Color(0xFFF7F0E8),
      indicatorColor: const Color(0x1A8B6842),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: active ? const Color(0xFF8B6842) : const Color(0xFF8F7B6B),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? const Color(0xFF8B6842) : const Color(0xFF8F7B6B),
        );
      }),
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
