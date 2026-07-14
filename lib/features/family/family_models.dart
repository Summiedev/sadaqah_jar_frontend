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
    required this.coverEmoji,
    required this.memberCount,
    required this.progress,
    required this.lastActivity,
    required this.daysRemaining,
    required this.goalLabel,
    required this.members,
    required this.goals,
    this.inviteCode = 'MIZAN-AHMAD-7Q2',
  });

  final String id;
  final String name;
  final String coverEmoji;
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
// MOCK DATA
// ─────────────────────────────────────────────────────────────

const List<FamilyJar> _jars = [
  FamilyJar(
    id: 'ahmad',
    name: 'The Ahmad Family',
    coverEmoji: '🌿',
    memberCount: 8,
    progress: 0.73,
    lastActivity: 'Fatimah shared a reflection',
    daysRemaining: 9,
    goalLabel: 'Monthly Giving',
    inviteCode: 'MIZAN-AHMAD-7Q2',
    members: [
      FamilyMember(
        id: 'm1',
        name: 'Yusuf Ahmad',
        role: 'Admin · Father',
        status: 'Contributed today',
        accent: fBronze,
        joined: 'Joined Mar 2024',
        milestones: ['30 days of morning adhkar', 'Ramadan completed together', '50 acts shared'],
        recentActivity: ['Logged an act of charity', 'Shared a weekly reflection'],
        reflections: ['Grateful we could help someone today.', 'May Allah keep our home gentle.'],
        contributedToday: true,
      ),
      FamilyMember(
        id: 'm2',
        name: 'Fatimah Ahmad',
        role: 'Mother',
        status: 'Shared reflection',
        accent: fOlive,
        joined: 'Joined Mar 2024',
        milestones: ['Consistent evening remembrance', 'Led a family goal'],
        recentActivity: ['Shared a weekly reflection', 'Completed morning adhkar'],
        reflections: ['Alhamdulillah for another week together.'],
        contributedToday: true,
      ),
      FamilyMember(
        id: 'm3',
        name: 'Aisha Ahmad',
        role: 'Daughter',
        status: 'Completed morning adhkar',
        accent: Color(0xFFB06B45),
        joined: 'Joined Apr 2024',
        milestones: ['First reflection written'],
        recentActivity: ['Completed morning adhkar'],
        reflections: ['Small things matter most.'],
      ),
      FamilyMember(
        id: 'm4',
        name: 'Omar Ahmad',
        role: 'Son',
        status: 'Contributed today',
        accent: Color(0xFF6E8B6B),
        joined: 'Joined Apr 2024',
        milestones: ['7-day streak of kindness'],
        recentActivity: ['Logged an act of charity'],
        reflections: [],
        contributedToday: true,
      ),
      FamilyMember(
        id: 'm5',
        name: 'Maryam Ahmad',
        role: 'Daughter',
        status: 'Shared reflection',
        accent: Color(0xFF9A6A3A),
        joined: 'Joined May 2024',
        milestones: [],
        recentActivity: ['Shared a weekly reflection'],
        reflections: ['May Allah accept our efforts.'],
      ),
      FamilyMember(
        id: 'm6',
        name: 'Ibrahim Ahmad',
        role: 'Son',
        status: 'Quiet today',
        accent: Color(0xFF7C6BA8),
        joined: 'Joined May 2024',
        milestones: [],
        recentActivity: ['Completed morning adhkar'],
        reflections: [],
      ),
      FamilyMember(
        id: 'm7',
        name: 'Hafsa Ahmad',
        role: 'Daughter',
        status: 'Contributed today',
        accent: Color(0xFFC28A53),
        joined: 'Joined Jun 2024',
        milestones: ['Helped a neighbour'],
        recentActivity: ['Logged an act of charity'],
        reflections: ['Kindness is its own reward.'],
        contributedToday: true,
      ),
      FamilyMember(
        id: 'm8',
        name: 'Bilal Ahmad',
        role: 'Son',
        status: 'Completed morning adhkar',
        accent: Color(0xFF4B77C4),
        joined: 'Joined Jun 2024',
        milestones: [],
        recentActivity: ['Completed morning adhkar'],
        reflections: [],
      ),
    ],
    goals: [
      FamilyGoal(id: 'g1', title: 'Monthly Giving', subtitle: 'A steady stream of small goodness', progress: 0.73, actsDone: 73, actsTarget: 100),
      FamilyGoal(id: 'g2', title: 'School Support', subtitle: 'Helping a cousin with studies', progress: 0.4, actsDone: 12, actsTarget: 30, accent: fOlive),
      FamilyGoal(id: 'g3', title: 'Masjid Project', subtitle: 'Community cleaning morning', progress: 0.85, actsDone: 17, actsTarget: 20, accent: Color(0xFF9A6A3A)),
    ],
  ),
  FamilyJar(
    id: 'parents',
    name: 'Parents',
    coverEmoji: '🤍',
    memberCount: 4,
    progress: 0.52,
    lastActivity: 'A family member completed a private act',
    daysRemaining: 12,
    goalLabel: 'Monthly Giving',
    inviteCode: 'MIZAN-PARENT-3K9',
    members: [
      FamilyMember(id: 'p1', name: 'Hajjah Amina', role: 'Grandmother', status: 'Shared reflection', accent: fOlive, joined: 'Joined Jan 2024', milestones: ['Ramadan together'], recentActivity: ['Shared a weekly reflection'], reflections: ['Age is softened by remembrance.']),
      FamilyMember(id: 'p2', name: 'Abdullah Sr', role: 'Grandfather', status: 'Contributed today', accent: fBronze, joined: 'Joined Jan 2024', milestones: ['Daily du\'a circle'], recentActivity: ['Logged an act of charity'], reflections: [], contributedToday: true),
      FamilyMember(id: 'p3', name: 'Uncle Tariq', role: 'Uncle', status: 'Completed morning adhkar', accent: Color(0xFF6E8B6B), joined: 'Joined Feb 2024', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
      FamilyMember(id: 'p4', name: 'Aunt Salma', role: 'Aunt', status: 'Quiet today', accent: Color(0xFFB06B45), joined: 'Joined Feb 2024', milestones: [], recentActivity: ['Shared a weekly reflection'], reflections: ['May we meet in Jannah.']),
    ],
    goals: [
      FamilyGoal(id: 'g1', title: 'Monthly Giving', subtitle: 'Supporting one another quietly', progress: 0.52, actsDone: 52, actsTarget: 100),
      FamilyGoal(id: 'g2', title: 'Orphan Sponsorship', subtitle: 'A long-term act of love', progress: 0.3, actsDone: 9, actsTarget: 30, accent: fOlive),
    ],
  ),
  FamilyJar(
    id: 'ramadan',
    name: 'Ramadan Giving Circle',
    coverEmoji: '🌙',
    memberCount: 15,
    progress: 0.88,
    lastActivity: 'The family reached 88% of this month\'s goal',
    daysRemaining: 4,
    goalLabel: 'Ramadan Goal',
    inviteCode: 'MIZAN-RAMAD-2X8',
    members: [
      FamilyMember(id: 'r1', name: 'Layla', role: 'Organiser', status: 'Contributed today', accent: fBronze, joined: 'Joined Feb 2025', milestones: ['Led 3 circles'], recentActivity: ['Logged an act of charity'], reflections: ['Ramadan is a school of mercy.'], contributedToday: true),
      FamilyMember(id: 'r2', name: 'Zayn', role: 'Member', status: 'Completed morning adhkar', accent: fOlive, joined: 'Joined Feb 2025', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
      FamilyMember(id: 'r3', name: 'Noor', role: 'Member', status: 'Shared reflection', accent: Color(0xFF9A6A3A), joined: 'Joined Feb 2025', milestones: [], recentActivity: ['Shared a weekly reflection'], reflections: ['The nights feel lighter this year.']),
      FamilyMember(id: 'r4', name: 'Hamza', role: 'Member', status: 'Contributed today', accent: Color(0xFF6E8B6B), joined: 'Joined Mar 2025', milestones: [], recentActivity: ['Logged an act of charity'], reflections: [], contributedToday: true),
      FamilyMember(id: 'r5', name: 'Sakina', role: 'Member', status: 'Quiet today', accent: Color(0xFFB06B45), joined: 'Joined Mar 2025', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
      FamilyMember(id: 'r6', name: 'Idris', role: 'Member', status: 'Shared reflection', accent: Color(0xFF7C6BA8), joined: 'Joined Mar 2025', milestones: [], recentActivity: ['Shared a weekly reflection'], reflections: ['Grateful for this circle.']),
      FamilyMember(id: 'r7', name: 'Ruqayyah', role: 'Member', status: 'Contributed today', accent: Color(0xFFC28A53), joined: 'Joined Mar 2025', milestones: [], recentActivity: ['Logged an act of charity'], reflections: [], contributedToday: true),
      FamilyMember(id: 'r8', name: 'Taha', role: 'Member', status: 'Completed morning adhkar', accent: Color(0xFF4B77C4), joined: 'Joined Mar 2025', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
    ],
    goals: [
      FamilyGoal(id: 'g1', title: 'Ramadan Goal', subtitle: 'Iftar packs for neighbours', progress: 0.88, actsDone: 88, actsTarget: 100),
      FamilyGoal(id: 'g2', title: 'Food Drive', subtitle: 'Weekly pantry top-up', progress: 0.6, actsDone: 18, actsTarget: 30, accent: fOlive),
      FamilyGoal(id: 'g3', title: 'Masjid Project', subtitle: 'Taraweeh water station', progress: 0.45, actsDone: 9, actsTarget: 20, accent: Color(0xFF9A6A3A)),
    ],
  ),
  FamilyJar(
    id: 'food',
    name: 'Community Food Drive',
    coverEmoji: '🫶',
    memberCount: 32,
    progress: 0.64,
    lastActivity: 'A family member completed a private act of charity',
    daysRemaining: 21,
    goalLabel: 'Food Drive',
    inviteCode: 'MIZAN-FOOD-9L4',
    members: [
      FamilyMember(id: 'c1', name: 'Sister Khadija', role: 'Coordinator', status: 'Contributed today', accent: fBronze, joined: 'Joined Sep 2024', milestones: ['100 meals shared'], recentActivity: ['Logged an act of charity'], reflections: ['Every plate is a prayer.'], contributedToday: true),
      FamilyMember(id: 'c2', name: 'Brother Saleh', role: 'Volunteer', status: 'Completed morning adhkar', accent: fOlive, joined: 'Joined Sep 2024', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
      FamilyMember(id: 'c3', name: 'Umm Yahya', role: 'Volunteer', status: 'Shared reflection', accent: Color(0xFF9A6A3A), joined: 'Joined Oct 2024', milestones: [], recentActivity: ['Shared a weekly reflection'], reflections: ['Community is a mercy.']),
      FamilyMember(id: 'c4', name: 'Anas', role: 'Volunteer', status: 'Contributed today', accent: Color(0xFF6E8B6B), joined: 'Joined Oct 2024', milestones: [], recentActivity: ['Logged an act of charity'], reflections: [], contributedToday: true),
      FamilyMember(id: 'c5', name: 'Rahma', role: 'Volunteer', status: 'Quiet today', accent: Color(0xFFB06B45), joined: 'Joined Nov 2024', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
      FamilyMember(id: 'c6', name: 'Yahya', role: 'Volunteer', status: 'Shared reflection', accent: Color(0xFF7C6BA8), joined: 'Joined Nov 2024', milestones: [], recentActivity: ['Shared a weekly reflection'], reflections: ['Small hands, big hearts.']),
      FamilyMember(id: 'c7', name: 'Sumayyah', role: 'Volunteer', status: 'Contributed today', accent: Color(0xFFC28A53), joined: 'Joined Dec 2024', milestones: ['Led a weekend shift'], recentActivity: ['Logged an act of charity'], reflections: [], contributedToday: true),
      FamilyMember(id: 'c8', name: 'Musa', role: 'Volunteer', status: 'Completed morning adhkar', accent: Color(0xFF4B77C4), joined: 'Joined Dec 2024', milestones: [], recentActivity: ['Completed morning adhkar'], reflections: []),
    ],
    goals: [
      FamilyGoal(id: 'g1', title: 'Food Drive', subtitle: 'Monthly pantry for 12 families', progress: 0.64, actsDone: 64, actsTarget: 100),
      FamilyGoal(id: 'g2', title: 'Orphan Sponsorship', subtitle: 'Back-to-school kits', progress: 0.35, actsDone: 14, actsTarget: 40, accent: fOlive),
    ],
  ),
];

const List<String> pendingRequests = [
  'Rania Khan — invited by Fatimah',
  'Uncle Imran — invited by Yusuf',
  'Cousin Huda — invited by Aisha',
];

List<FamilyJar> allFamilies() => _jars;

FamilyJar? getFamilyById(String id) {
  for (final j in _jars) {
    if (j.id == id) return j;
  }
  return null;
}

FamilyMember? getMember(FamilyJar jar, String id) {
  for (final m in jar.members) {
    if (m.id == id) return m;
  }
  return null;
}
