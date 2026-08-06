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

// Dark theme tokens (kept separate so light tokens remain untouched)
const Color kScaffoldDark = Color(0xFF0F1412); // not pure black, deep charcoal
const Color kSurfaceDark = Color(0xFF111417);
const Color kPaperDark = Color(0xFF121619);
const Color kInkDark = Color(0xFFECE7DE); // readable on dark
const Color kMutedDark = Color(0xFFBDB6AF);
const Color kLineDark = Color(0x1AFFFFFF);
const Color kElevatedDark = Color(0xFF1A201D);
const Color kBronzeDarkMode = Color(0xFFD1A879);

ThemeData buildDarkTheme() {
  const seed = kBronze;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    surface: kSurfaceDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kScaffoldDark,
    fontFamily: 'Georgia',
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerColor: kLineDark,
    disabledColor: kMutedDark.withValues(alpha: 0.38),
    dividerTheme: const DividerThemeData(color: kLineDark, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: kInkDark),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w800, color: kInkDark),
      titleMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: kInkDark),
      titleSmall: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: kInkDark),
      bodyLarge: TextStyle(fontFamily: 'Georgia', color: kInkDark),
      bodyMedium: TextStyle(fontFamily: 'Georgia', color: kMutedDark),
      bodySmall: TextStyle(fontFamily: 'Georgia', color: kMutedDark),
      labelLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w800, color: kInkDark),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBronzeDarkMode,
        foregroundColor: kScaffoldDark,
        disabledBackgroundColor: kElevatedDark,
        disabledForegroundColor: kMutedDark,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kElevatedDark,
      hintStyle: const TextStyle(color: kMutedDark),
      labelStyle: const TextStyle(color: kMutedDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLineDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLineDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBronzeDarkMode, width: 1.5)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kElevatedDark,
      contentTextStyle: const TextStyle(color: kInkDark, fontWeight: FontWeight.w600),
      actionTextColor: kBronzeDarkMode,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kElevatedDark,
      selectedColor: kBronzeDarkMode.withValues(alpha: 0.22),
      labelStyle: const TextStyle(color: kInkDark, fontWeight: FontWeight.w700),
      secondaryLabelStyle: const TextStyle(color: kInkDark, fontWeight: FontWeight.w800),
      side: const BorderSide(color: kLineDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kInkDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: kInkDark),
      titleTextStyle: TextStyle(
        color: kInkDark,
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
      backgroundColor: kSurfaceDark,
      indicatorColor: kBronzeDarkMode.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: active ? kBronzeDarkMode : kMutedDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? kBronzeDarkMode : kMutedDark,
        );
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSurfaceDark,
      selectedItemColor: kBronzeDarkMode,
      unselectedItemColor: kMutedDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kElevatedDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: kSurfaceDark, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: kSurfaceDark, surfaceTintColor: Colors.transparent),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? kBronzeDarkMode : kMutedDark),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? kBronzeDarkMode.withValues(alpha: 0.35) : kElevatedDark),
    ),
  );
}

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
    dividerColor: kLine,
    disabledColor: kMutedLight.withValues(alpha: 0.45),
    iconTheme: const IconThemeData(color: kInk),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBronze,
        foregroundColor: kPaper,
        disabledBackgroundColor: kClay,
        disabledForegroundColor: kMuted,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kPaper,
      hintStyle: const TextStyle(color: kMutedLight),
      labelStyle: const TextStyle(color: kMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLine)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBronze, width: 1.5)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kInk,
      contentTextStyle: const TextStyle(color: kPaper, fontWeight: FontWeight.w600),
      actionTextColor: kBronzeLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kPaper,
      selectedColor: kSoftBronze,
      labelStyle: const TextStyle(color: kMuted, fontWeight: FontWeight.w700),
      secondaryLabelStyle: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
      side: const BorderSide(color: kLine),
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
      indicatorColor: kBronze.withValues(alpha: 0.1),
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
    dialogTheme: DialogThemeData(backgroundColor: kPaper, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: kPaper, surfaceTintColor: Colors.transparent),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? kBronze : kMutedLight),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? kBronze.withValues(alpha: 0.32) : kClay),
    ),
  );
}
