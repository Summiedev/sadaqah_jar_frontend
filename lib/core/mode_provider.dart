import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The companion mode chosen by the user.
/// 0 = Personal  ·  "My personal journey."
/// 1 = Family    ·  "Grow together with family."
/// 2 = Both      ·  Personal + Family, combined.
const int kModePersonal = 0;
const int kModeFamily = 1;
const int kModeBoth = 2;

const String _kMode = 'mizan.mode';
const String _kModeChosen = 'mizan.mode_chosen';

class ModeNotifier extends Notifier<int> {
  @override
  int build() {
    // Synchronous default; the persisted value is loaded a moment later.
    _load();
    return kModeBoth;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kMode);
    if (stored != null && stored != state) {
      state = stored;
    }
  }

  Future<void> setMode(int mode) async {
    if (mode == state) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMode, mode);
    await prefs.setBool(_kModeChosen, true);
  }
}

final modeProvider = NotifierProvider<ModeNotifier, int>(ModeNotifier.new);

class ModeMeta {
  const ModeMeta({required this.label, required this.tagline, required this.icon, required this.accent});

  final String label;
  final String tagline;
  final IconData icon;
  final Color accent;
}

const Map<int, ModeMeta> kModeMeta = {
  kModePersonal: ModeMeta(
    label: 'Personal',
    tagline: 'My personal journey.',
    icon: Icons.person_outline_rounded,
    accent: Color(0xFF9A6A3A),
  ),
  kModeFamily: ModeMeta(
    label: 'Family',
    tagline: 'Grow together with family.',
    icon: Icons.groups_outlined,
    accent: Color(0xFF1FA36B),
  ),
  kModeBoth: ModeMeta(
    label: 'Both',
    tagline: 'Solitude and togetherness, in one.',
    icon: Icons.auto_awesome_outlined,
    accent: Color(0xFF4A8DF7),
  ),
};
