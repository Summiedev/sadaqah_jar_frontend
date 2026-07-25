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
// MOCK DATA — REMOVED
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

const List<FamilyJar> _jars = [];

const List<String> pendingRequests = [];

List<FamilyJar> allFamilies() => _jars;

FamilyJar? getFamilyById(String id) => null;

FamilyMember? getMember(FamilyJar jar, String id) => null;
