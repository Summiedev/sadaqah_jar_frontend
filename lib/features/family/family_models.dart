import 'package:flutter/material.dart';

import 'family_theme.dart';

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.accent,
    required this.joined,
    required this.milestones,
    required this.recentActivity,
    required this.reflections,
    this.contributedToday = false,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final Color accent;
  final String joined;
  final List<String> milestones;
  final List<String> recentActivity;
  final List<String> reflections;
  final bool contributedToday;
}

class FamilyGoal {
  const FamilyGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.actsDone,
    required this.actsTarget,
    this.accent = fBronze,
  });

  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final int actsDone;
  final int actsTarget;
  final Color accent;
}

class FamilyJar {
  const FamilyJar({
    required this.id,
    required this.name,
    required this.coverIcon,
    required this.memberCount,
    required this.progress,
    required this.lastActivity,
    required this.daysRemaining,
    required this.goalLabel,
    required this.members,
    required this.goals,
    this.inviteCode = '',
  });

  final String id;
  final String name;
  final IconData coverIcon;
  final int memberCount;
  final double progress;
  final String lastActivity;
  final int daysRemaining;
  final String goalLabel;
  final List<FamilyMember> members;
  final List<FamilyGoal> goals;
  final String inviteCode;
}

// ─────────────────────────────────────────────────────────────
// MOCK DATA - REMOVED
// ─────────────────────────────────────────────────────────────
//
// The hardcoded _jars list was removed because it contained
// fake user-facing data (e.g. "Hajjah Amina", "Ramadan together",
// "The Ahmad Family") that does not represent real user data.
//
// All family screens now fetch from the backend.
// The helper functions below return empty data until backend
// integration is wired into each family sub-screen.
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// LOCAL CACHE
// ─────────────────────────────────────────────────────────────

final List<FamilyJar> _familyCache = [];
final List<String> _pendingRequests = [];

void cacheFamilies(List<FamilyJar> families) {
  _familyCache.clear();
  _familyCache.addAll(families);
}

/// Keeps the older family sub-screens backed by the same server response as
/// the current family hub. This is intentionally tolerant of partial list
/// responses; detail screens fetch authoritative members and goals again.
void cacheFamiliesFromApi(List<Map<String, dynamic>> rows) {
  cacheFamilies(
    rows
        .map((row) {
          final goals =
              (row['goals'] as List?)
                  ?.whereType<Map>()
                  .map(
                    (g) => FamilyGoal(
                      id: '${g['id'] ?? ''}',
                      title: g['title']?.toString() ?? 'Family goal',
                      subtitle: g['subtitle']?.toString() ?? '',
                      progress: ((g['progress'] as num?)?.toDouble() ?? 0)
                          .clamp(0, 1),
                      actsDone: (g['acts_done'] as num?)?.toInt() ?? 0,
                      actsTarget: (g['acts_target'] as num?)?.toInt() ?? 0,
                    ),
                  )
                  .toList() ??
              const <FamilyGoal>[];
          return FamilyJar(
            id: '${row['id'] ?? ''}',
            name: row['name']?.toString() ?? 'Family',
            coverIcon: Icons.favorite_border_rounded,
            memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
            progress: ((row['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1),
            lastActivity: row['last_activity']?.toString() ?? '',
            daysRemaining: (row['days_remaining'] as num?)?.toInt() ?? 0,
            goalLabel: row['goal_label']?.toString() ?? '',
            members: const [],
            goals: goals,
            inviteCode: row['invite_code']?.toString() ?? '',
          );
        })
        .where((family) => family.id.isNotEmpty)
        .toList(),
  );
}

List<String> get pendingRequests => _pendingRequests;

FamilyJar? getFamilyById(String id) {
  try {
    return _familyCache.firstWhere((f) => f.id == id);
  } on StateError {
    return null;
  }
}

List<FamilyJar> allFamilies() => List.unmodifiable(_familyCache);

FamilyMember? getMember(FamilyJar? jar, String id) {
  if (jar == null) return null;
  try {
    return jar.members.firstWhere((m) => m.id == id);
  } on StateError {
    return null;
  }
}
