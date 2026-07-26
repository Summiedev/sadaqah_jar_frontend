import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// MIZAN · CANONICAL DESIGN TOKENS
// Single source of truth for the entire app.
// Bronze: 0xFF8B6842
// Paper:   0xFFFFFCF8
// ─────────────────────────────────────────────────────────────

const Color kBronze = Color(0xFF8B6842);
const Color kBronzeDark = Color(0xFF6D4F32);
const Color kBronzeLight = Color(0xFFB38964);
const Color kPaper = Color(0xFFFFFCF8);
const Color kIvory = Color(0xFFF7F0E7);
const Color kSurface = Color(0xFFF7F0E8);
const Color kScaffold = Color(0xFFF4EBDD);
const Color kInk = Color(0xFF2F241E);
const Color kMuted = Color(0xFF6D5B4D);
const Color kMutedLight = Color(0xFF9A8A7A);
const Color kLine = Color(0xFFE8DDD1);
const Color kDanger = Color(0xFFA8554E);
const Color kDangerBg = Color(0xFFFFF0EE);
const Color kDangerBorder = Color(0xFFF0BCB5);
const Color kDraftBg = Color(0xFFF5E0E0);
const Color kSuccessBg = Color(0xFFEAF3E0);
const Color kSuccessBorder = Color(0xFFC9D8B4);
const Color kSage = Color(0xFF58705C);
const Color kSlate = Color(0xFF687EA5);
const Color kSageSoft = Color(0xFFD4E0C8);
const Color kSoftBronze = Color(0xFFF0E3D4);
const Color kSoftSage = Color(0xFFDCE7D8);
const Color kClay = Color(0xFFE2D0BE);
const Color kClayLight = Color(0xFFE8DCCF);
const Color kClayPale = Color(0xFFF3E9DE);
const Color kOlive = Color(0xFF749B75);
const Color kOliveSoft = Color(0xFFD4E0C8);
const Color kStone = Color(0xFF6D5B4D);
const Color kStoneLight = Color(0xFF9A8A7A);
const Color kStonePale = Color(0xFFB8A28E);
const Color kWhite = Color(0xFFFFFFFF);

ThemeData buildAppTheme() {
  const seed = kBronze;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: kSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kScaffold,
    fontFamily: 'Georgia',
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kPaper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLine)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBronze, width: 1.5)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: kInk),
      titleTextStyle: TextStyle(
        color: kInk,
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
      backgroundColor: kSurface,
      indicatorColor: const Color(0x1A8B6842),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: active ? kBronze : kStoneLight,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? kBronze : kStoneLight,
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
      backgroundColor: kSurface,
      selectedItemColor: kBronze,
      unselectedItemColor: kStoneLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kPaper,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
