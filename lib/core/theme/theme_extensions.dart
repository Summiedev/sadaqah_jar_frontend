import 'package:flutter/material.dart';
import 'app_theme.dart';

extension AppPalette on BuildContext {
  Brightness get _brightness => Theme.of(this).brightness;

  Color get scaffold => _brightness == Brightness.dark ? kScaffoldDark : kScaffold;
  Color get surface => _brightness == Brightness.dark ? kSurfaceDark : kSurface;
  Color get paper => _brightness == Brightness.dark ? kPaperDark : kPaper;
  Color get ink => _brightness == Brightness.dark ? kInkDark : kInk;
  Color get muted => _brightness == Brightness.dark ? kMutedDark : kMuted;
  Color get line => _brightness == Brightness.dark ? kLineDark : kLine;
  Color get bronze => kBronze;
  Color get bronzeLight => kBronzeLight;
}
