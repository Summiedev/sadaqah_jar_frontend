import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../widgets/notification_action_button.dart';
import 'analytics_screen.dart';
import 'family_jar_detail_screen.dart';
import 'leaderboard_screen.dart';
import 'notification_center_screen.dart';
import 'settings_screen.dart';
import 'streak_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onLogout, this.onUnreadCountChanged});

  final Future<void> Function() onLogout;
  final ValueChanged<int>? onUnreadCountChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(12)),
          child: FutureBuilder<_ProfileContext>(
            future: _loadProfileContext(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final userId = data?.userId;
              final profile = data?.profile;
              final isAdmin = data?.role == 'ADMIN';
              final familyJarId = data?.familyJarId;

              return ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Profile', style: TextStyle(fontSize: s(30), fontWeight: FontWeight.w900, color: const Color(0xFF2F251E))),
                            SizedBox(height: s(4)),
                            Text('Your account, family jar, and personal momentum', style: TextStyle(fontSize: s(13.2), color: const Color(0xFF6A5E52))),
                          ],
                        ),
                      ),
                      NotificationActionButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationCenterScreen(onUnreadCountChanged: onUnreadCountChanged),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: s(8)),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: const Color(0xFF8B6842), size: s(24)),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(onLogout: onLogout)));
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: s(16)),
                  Container(
                    padding: EdgeInsets.all(s(18)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8D7C1), Color(0xFFF7F3ED)],
                      ),
                      borderRadius: BorderRadius.circular(s(24)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: s(34),
                          backgroundColor: const Color(0xFF9B734F),
                          backgroundImage: profile?.avatarData != null && profile!.avatarData!.isNotEmpty
                              ? MemoryImage(base64Decode(profile.avatarData!))
                              : null,
                          child: profile?.avatarData == null || profile!.avatarData!.isEmpty
                              ? Icon(Icons.person, color: Colors.white, size: s(34))
                              : null,
                        ),
                        SizedBox(width: s(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.username?.isNotEmpty == true ? profile!.username! : 'User #${userId ?? '...'}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: s(21), color: const Color(0xFF2F251E)),
                              ),
                              SizedBox(height: s(4)),
                              Text(
                                profile?.email?.isNotEmpty == true ? profile!.email! : 'Connected account',
                                style: TextStyle(color: const Color(0xFF7A5B3E), fontSize: s(13.5)),
                              ),
                              SizedBox(height: s(8)),
                              Wrap(
                                spacing: s(8),
                                runSpacing: s(8),
                                children: [
                                  _MiniPill(label: 'Family jar ${familyJarId != null ? '#$familyJarId' : 'unset'}'),
                                  _MiniPill(label: data?.role ?? 'USER'),
                                  _MiniPill(label: profile?.email?.isNotEmpty == true ? 'Email linked' : 'Pending verification'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(14)),
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<StreakInfo>(
                          future: BackendApi.instance.getStreak(),
                          builder: (context, streakSnapshot) {
                            final streak = streakSnapshot.data;
                            return _InfoCard(
                              scale: scale,
                              title: 'Current streak',
                              value: '${streak?.currentStreak ?? 0} days',
                              subtitle: 'Longest: ${streak?.longestStreak ?? 0} days',
                              icon: Icons.local_fire_department_outlined,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: FutureBuilder<RankSummary>(
                          future: BackendApi.instance.getMyRank(),
                          builder: (context, rankSnapshot) {
                            final rank = rankSnapshot.data;
                            return _InfoCard(
                              scale: scale,
                              title: 'Leaderboard',
                              value: rank?.globalRank != null ? '#${rank!.globalRank} · ${rank.globalScore ?? 0} stars' : 'No rank yet',
                              subtitle: 'Ramadan: ${rank?.ramadanRank != null ? '#${rank!.ramadanRank}' : '-'}',
                              icon: Icons.emoji_events_outlined,
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(14)),
                  _ProfileActionCard(
                    scale: scale,
                    title: 'Family Jar',
                    value: familyJarId != null ? 'Saved jar #$familyJarId' : 'No family jar saved yet',
                    subtitle: 'Open your family leaderboard and top contributor view.',
                    icon: Icons.groups_2_outlined,
                    onTap: familyJarId == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: familyJarId)),
                            );
                          },
                  ),
                  SizedBox(height: s(10)),
                  _ProfileTile(
                    scale: scale,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationCenterScreen(onUnreadCountChanged: onUnreadCountChanged),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: s(10)),
                  _ProfileTile(
                    scale: scale,
                    icon: Icons.insights_outlined,
                    title: 'Analytics',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                    },
                  ),
                  SizedBox(height: s(10)),
                  _ProfileTile(
                    scale: scale,
                    icon: Icons.local_fire_department_outlined,
                    title: 'Streaks',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StreakScreen()));
                    },
                  ),
                  SizedBox(height: s(10)),
                  _ProfileTile(
                    scale: scale,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(onLogout: onLogout)));
                    },
                  ),
                  if (isAdmin) ...[
                    SizedBox(height: s(10)),
                    _ProfileTile(
                      scale: scale,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin panel',
                      onTap: () {
                        Navigator.of(context).pushNamed('/admin');
                      },
                    ),
                  ],
                  SizedBox(height: s(10)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await onLogout();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9E4D46),
                        side: const BorderSide(color: Color(0xFFCFB8A5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Log out'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_ProfileContext> _loadProfileContext() async {
    final results = await Future.wait([
      BackendApi.instance.getAccountSnapshot(),
      BackendApi.instance.getLastFamilyJarId(),
      BackendApi.instance.getUserProfile(),
    ]);

    return _ProfileContext(
      userId: (results[0] as AccountSnapshot?)?.userId,
      profile: results[0] as AccountSnapshot?,
      familyJarId: results[1] as int?,
      role: (results[2] as UserProfile?)?.role ?? 'USER',
    );
  }
}

class _ProfileContext {
  _ProfileContext({required this.userId, required this.profile, required this.familyJarId, required this.role});

  final int? userId;
  final AccountSnapshot? profile;
  final int? familyJarId;
  final String role;
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6A5E52))),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.scale, required this.title, required this.value, required this.subtitle, required this.icon, this.onTap});

  final double scale;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s(18)),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(s(14)),
          child: Row(
            children: [
              Container(
                width: s(42),
                height: s(42),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D5C7),
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                child: Icon(icon, color: const Color(0xFF8B6842), size: s(22)),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12))),
                    SizedBox(height: s(2)),
                    Text(value, style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(16), fontWeight: FontWeight.w800)),
                    SizedBox(height: s(2)),
                    Text(subtitle, style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12))),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: s(16), color: const Color(0xFF7A5B3E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.scale, required this.icon, required this.title, required this.onTap});

  final double scale;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s(18)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(14)),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8B6842), size: s(22)),
              SizedBox(width: s(12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF3B3327),
                    fontSize: s(16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: s(16), color: const Color(0xFF7A5B3E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.scale, required this.title, required this.value, required this.subtitle, required this.icon, this.onTap});

  final double scale;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s(18)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Row(
            children: [
              Container(
                width: s(42),
                height: s(42),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D5C7),
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                child: Icon(icon, color: const Color(0xFF8B6842), size: s(22)),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12))),
                    SizedBox(height: s(2)),
                    Text(value, style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(16), fontWeight: FontWeight.w800)),
                    SizedBox(height: s(2)),
                    Text(subtitle, style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12))),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: s(16), color: const Color(0xFF7A5B3E)),
            ],
          ),
        ),
      ),
    );
  }
}