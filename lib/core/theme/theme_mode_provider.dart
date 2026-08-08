import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kThemeModePrefsKey = 'mizan.theme_mode';

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

Future<ThemeMode> loadInitialThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getInt(kThemeModePrefsKey);
  if (stored == null) return ThemeMode.system;
  return ThemeMode.values.elementAt(
    stored.clamp(0, ThemeMode.values.length - 1),
  );
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ref.watch(initialThemeModeProvider);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(kThemeModePrefsKey);
    if (stored != null) {
      final mode = ThemeMode.values.elementAt(
        stored.clamp(0, ThemeMode.values.length - 1),
      );
      if (mode != state) state = mode;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kThemeModePrefsKey, ThemeMode.values.indexOf(mode));
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
