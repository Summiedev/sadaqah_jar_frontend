import 'package:flutter/material.dart';
import 'app_theme.dart';

extension AppPalette on BuildContext {
  MizanColors get colors =>
      Theme.of(this).extension<MizanColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? MizanColors.dark
          : MizanColors.light);

  Color get scaffold => colors.background;
  Color get surface => colors.surfaceContainer;
  Color get paper => colors.surfaceElevated;
  Color get ink => colors.textPrimary;
  Color get muted => colors.textSecondary;
  Color get mutedLight => colors.textMuted;
  Color get line => colors.border;
  Color get lineSubtle => colors.borderSubtle;
  Color get bronze => colors.primary;
  Color get bronzeLight => colors.accent;
  Color get softBronze => colors.primaryContainer;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.error;
}
