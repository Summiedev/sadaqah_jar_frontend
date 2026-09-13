import 'package:flutter/material.dart';

import 'design_tokens.dart';

// ─────────────────────────────────────────────────────────────
// MIZAN · CANONICAL DESIGN TOKENS
// Single source of truth for the entire app.
// Bronze: 0xFF8B6842
// Paper:   0xFFFFFCF8
// ─────────────────────────────────────────────────────────────

const Color kBronze = Color(0xFF8A633A);
const Color kBronzeDark = Color(0xFF6F4E2D);
const Color kBronzeLight = Color(0xFFB88B5B);
const Color kPaper = Color(0xFFFFFCF7);
const Color kIvory = Color(0xFFF8F0E5);
const Color kSurface = Color(0xFFF3E8DA);
const Color kScaffold = Color(0xFFF6EFE5);
const Color kInk = Color(0xFF2F251F);
const Color kMuted = Color(0xFF66584D);
const Color kMutedLight = Color(0xFF83766A);
const Color kLine = Color(0xFFE2D4C5);
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
const Color kStonePale = Color(0xFFB09E8D);
const Color kWhite = Color(0xFFFFFFFF);

// Warm lifted dark surfaces, avoiding pure black and harsh white contrast.
const Color kScaffoldDark = Color(0xFF2E2A26);
const Color kSurfaceDark = Color(0xFF39332D);
const Color kPaperDark = Color(0xFF443C34);
const Color kInkDark = Color(0xFFF2EAE0);
const Color kMutedDark = Color(0xFFD3C8BB);
const Color kLineDark = Color(0xFF675D51);
const Color kElevatedDark = Color(0xFF50463C);
const Color kBronzeDarkMode = Color(0xFFD2A875);

@immutable
class MizanColors extends ThemeExtension<MizanColors> {
  const MizanColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconDisabled,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.overlay,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color accent;
  final Color accentSoft;
  final Color border;
  final Color borderSubtle;
  final Color divider;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconDisabled;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color overlay;
  final Color scrim;

  static const light = MizanColors(
    background: kScaffold,
    surface: kPaper,
    surfaceElevated: Color(0xFFFFF8EF),
    surfaceContainer: kSurface,
    surfaceContainerHigh: Color(0xFFEDE0D1),
    textPrimary: kInk,
    textSecondary: kMuted,
    textMuted: kMutedLight,
    textDisabled: Color(0xFFA99D92),
    textInverse: Color(0xFFFFF8EF),
    primary: kBronze,
    primaryContainer: kSoftBronze,
    onPrimary: Color(0xFFFFF8EF),
    onPrimaryContainer: Color(0xFF2C1B0F),
    secondary: kSage,
    secondaryContainer: kSoftSage,
    accent: kBronzeLight,
    accentSoft: kClayPale,
    border: kLine,
    borderSubtle: Color(0xFFEDE3D9),
    divider: kLine,
    success: kSage,
    successContainer: kSuccessBg,
    warning: Color(0xFFA6752D),
    warningContainer: Color(0xFFFFEBCB),
    error: kDanger,
    errorContainer: kDangerBg,
    info: kSlate,
    infoContainer: Color(0xFFE7EDF7),
    iconPrimary: kInk,
    iconSecondary: kMuted,
    iconDisabled: kMutedLight,
    inputBackground: kPaper,
    inputBorder: kLine,
    inputFocusedBorder: kBronze,
    overlay: Color(0xB3FFF8EF),
    scrim: Color(0x66000000),
  );

  static const dark = MizanColors(
    // A lifted charcoal hierarchy keeps long reading sessions comfortable and
    // gives cards, sheets, and dialogs visible separation without glare.
    background: Color(0xFF292725),
    surface: Color(0xFF34312D),
    surfaceElevated: Color(0xFF403A34),
    surfaceContainer: Color(0xFF3A3631),
    surfaceContainerHigh: Color(0xFF4A433B),
    textPrimary: Color(0xFFF3ECE4),
    textSecondary: Color(0xFFD1C7BB),
    textMuted: Color(0xFFB7AA9E),
    textDisabled: Color(0xFF968B81),
    textInverse: Color(0xFF251B12),
    primary: kBronzeDarkMode,
    primaryContainer: Color(0xFF594735),
    onPrimary: Color(0xFF24160C),
    onPrimaryContainer: Color(0xFFFFE6C7),
    secondary: Color(0xFFA7BEA4),
    secondaryContainer: Color(0xFF3D4B40),
    accent: Color(0xFFD0AA78),
    accentSoft: Color(0xFF514334),
    border: Color(0xFF766B61),
    borderSubtle: Color(0xFF665D54),
    divider: Color(0xFF6B6259),
    success: Color(0xFFA4BE9F),
    successContainer: Color(0xFF304131),
    warning: Color(0xFFDDB673),
    warningContainer: Color(0xFF513E25),
    error: Color(0xFFE08B82),
    errorContainer: Color(0xFF55312F),
    info: Color(0xFFB4C1DA),
    infoContainer: Color(0xFF303A49),
    iconPrimary: kInkDark,
    iconSecondary: kMutedDark,
    iconDisabled: Color(0xFF91877D),
    inputBackground: Color(0xFF322F2B),
    inputBorder: Color(0xFF766B61),
    inputFocusedBorder: kBronzeDarkMode,
    overlay: Color(0xCC292621),
    scrim: Color(0x99000000),
  );

  @override
  MizanColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textInverse,
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? accent,
    Color? accentSoft,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconDisabled,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusedBorder,
    Color? overlay,
    Color? scrim,
  }) {
    return MizanColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      overlay: overlay ?? this.overlay,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  MizanColors lerp(ThemeExtension<MizanColors>? other, double t) {
    if (other is! MizanColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return MizanColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceContainer: c(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: c(surfaceContainerHigh, other.surfaceContainerHigh),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      textDisabled: c(textDisabled, other.textDisabled),
      textInverse: c(textInverse, other.textInverse),
      primary: c(primary, other.primary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimary: c(onPrimary, other.onPrimary),
      onPrimaryContainer: c(onPrimaryContainer, other.onPrimaryContainer),
      secondary: c(secondary, other.secondary),
      secondaryContainer: c(secondaryContainer, other.secondaryContainer),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      divider: c(divider, other.divider),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      error: c(error, other.error),
      errorContainer: c(errorContainer, other.errorContainer),
      info: c(info, other.info),
      infoContainer: c(infoContainer, other.infoContainer),
      iconPrimary: c(iconPrimary, other.iconPrimary),
      iconSecondary: c(iconSecondary, other.iconSecondary),
      iconDisabled: c(iconDisabled, other.iconDisabled),
      inputBackground: c(inputBackground, other.inputBackground),
      inputBorder: c(inputBorder, other.inputBorder),
      inputFocusedBorder: c(inputFocusedBorder, other.inputFocusedBorder),
      overlay: c(overlay, other.overlay),
      scrim: c(scrim, other.scrim),
    );
  }
}

ThemeData buildDarkTheme() =>
    _buildMizanTheme(MizanColors.dark, Brightness.dark);

ThemeData buildAppTheme() =>
    _buildMizanTheme(MizanColors.light, Brightness.light);

ThemeData _buildMizanTheme(MizanColors colors, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.primary,
    brightness: brightness,
    surface: colors.surface,
  ).copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.primaryContainer,
    onPrimaryContainer: colors.onPrimaryContainer,
    secondary: colors.secondary,
    secondaryContainer: colors.secondaryContainer,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    onSurfaceVariant: colors.textSecondary,
    error: colors.error,
    errorContainer: colors.errorContainer,
    outline: colors.border,
    outlineVariant: colors.borderSubtle,
    scrim: colors.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[colors],
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    fontFamily: 'Roboto',
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerColor: colors.divider,
    disabledColor: colors.textDisabled,
    canvasColor: colors.background,
    cardColor: colors.surfaceElevated,
    highlightColor: colors.primary.withValues(alpha: isDark ? 0.10 : 0.08),
    hoverColor: colors.primary.withValues(alpha: isDark ? 0.10 : 0.06),
    splashColor: colors.primary.withValues(alpha: isDark ? 0.14 : 0.10),
    iconTheme: IconThemeData(color: colors.iconPrimary),
    primaryIconTheme: IconThemeData(color: colors.iconPrimary),
    textTheme: _buildTextTheme(colors),
    primaryTextTheme: _buildTextTheme(colors),
    dividerTheme: DividerThemeData(
      color: colors.divider,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: colors.iconPrimary),
      actionsIconTheme: IconThemeData(color: colors.iconPrimary),
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Georgia',
        height: 1.18,
      ),
      toolbarHeight: 60,
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 0 : 1,
      shadowColor: isDark ? Colors.transparent : const Color(0x1F8A633A),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MizanRadii.card),
        side: BorderSide(color: colors.borderSubtle),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Georgia',
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(
        color: colors.textSecondary,
        fontFamily: 'Georgia',
        fontSize: 14,
        height: 1.45,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MizanRadii.sheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceElevated,
      modalBackgroundColor: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: colors.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MizanRadii.sheet),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primary.withValues(alpha: isDark ? 0.20 : 0.11),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 0,
          color: active ? colors.primary : colors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? colors.primary : colors.iconSecondary,
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.surfaceContainerHigh,
        disabledForegroundColor: colors.textDisabled,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MizanRadii.control),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.surfaceElevated,
        foregroundColor: colors.textPrimary,
        disabledBackgroundColor: colors.surfaceContainer,
        disabledForegroundColor: colors.textDisabled,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : const Color(0x1F8A633A),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MizanRadii.control),
          side: BorderSide(color: colors.borderSubtle),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.textDisabled,
        side: BorderSide(color: colors.border),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MizanRadii.control),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.textDisabled,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled)
                  ? colors.iconDisabled
                  : colors.iconPrimary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.pressed)
                  ? colors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBackground,
      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      errorStyle: TextStyle(
        color: colors.error,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: colors.iconSecondary,
      suffixIconColor: colors.iconSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.inputFocusedBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MizanRadii.control),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:
          isDark ? colors.surfaceContainerHigh : colors.textPrimary,
      contentTextStyle: TextStyle(
        color: isDark ? colors.textPrimary : colors.textInverse,
        fontWeight: FontWeight.w700,
      ),
      actionTextColor: colors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceElevated,
      selectedColor: colors.primary.withValues(alpha: isDark ? 0.20 : 0.13),
      disabledColor: colors.surfaceContainer,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: colors.borderSubtle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Georgia',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.borderSubtle),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.iconSecondary,
      textColor: colors.textPrimary,
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Georgia',
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      subtitleTextStyle: TextStyle(
        color: colors.textSecondary,
        fontFamily: 'Georgia',
        fontSize: 12.5,
        height: 1.35,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? colors.primary.withValues(alpha: isDark ? 0.34 : 0.26)
                : colors.surfaceContainerHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? colors.primary.withValues(alpha: 0.35)
                : colors.border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.primary;
        if (states.contains(WidgetState.disabled)) {
          return colors.surfaceContainerHigh;
        }
        return colors.surfaceElevated;
      }),
      checkColor: WidgetStateProperty.all(colors.onPrimary),
      side: BorderSide(color: colors.border, width: 1.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? colors.primary
                : colors.iconSecondary,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.surfaceContainerHigh,
      circularTrackColor: colors.surfaceContainerHigh,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(colors.border),
      trackColor: WidgetStateProperty.all(colors.surfaceContainer),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: colors.textMuted,
      indicatorColor: colors.primary,
      dividerColor: colors.borderSubtle,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: colors.surfaceElevated,
      collapsedBackgroundColor: colors.surfaceElevated,
      textColor: colors.textPrimary,
      collapsedTextColor: colors.textPrimary,
      iconColor: colors.iconSecondary,
      collapsedIconColor: colors.iconSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.borderSubtle),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.borderSubtle),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      textStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.25),
      selectionHandleColor: colors.primary,
    ),
  );
}

TextTheme _buildTextTheme(MizanColors colors) {
  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 34,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 30,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 26,
      height: 1.16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 20,
      height: 1.22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Georgia',
      color: colors.textPrimary,
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textPrimary,
      fontSize: 16,
      height: 1.48,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textSecondary,
      fontSize: 14,
      height: 1.48,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textMuted,
      fontSize: 12.5,
      height: 1.42,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textPrimary,
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textSecondary,
      fontSize: 12.5,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Roboto',
      color: colors.textMuted,
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    ),
  );
}
