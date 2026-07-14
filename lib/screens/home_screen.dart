import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import 'analytics_screen.dart';
import 'archived_jars_screen.dart';
import 'family_jar_detail_screen.dart';
import 'jar_screen.dart';
import 'leaderboard_screen.dart';
import 'streak_screen.dart';
import '../widgets/live_jar_panel.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onFillJar;
  final VoidCallback onTabChanged;

  const HomeScreen({super.key, required this.onFillJar, required this.onTabChanged});

  Future<void> _showCreateFamilyJar(BuildContext context) async {
    final nameController = TextEditingController(text: 'Family Jar');
    final capacityController = TextEditingController(text: '33');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Create Group Jar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Jar name')),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create')),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      final response = await BackendApi.instance.createFamilyJar(
        name: nameController.text.trim(),
        capacity: int.tryParse(capacityController.text) ?? 33,
      );
      if (context.mounted) {
        final jarId = (response['jar_id'] as num?)?.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created group jar: ${response['invite_code'] ?? 'invite ready'}')),
        );
        if (jarId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: jarId)));
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _showJoinFamilyJar(BuildContext context) async {
    final inviteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Join Group Jar'),
          content: TextField(
            controller: inviteController,
            decoration: const InputDecoration(labelText: 'Invite code'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Join')),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      final response = await BackendApi.instance.joinFamilyJar(inviteCode: inviteController.text.trim());
      if (context.mounted) {
        final jarId = (response['jar_id'] as num?)?.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Joined group jar')),
        );
        if (jarId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: jarId)));
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _openPersonalJar(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JarScreen()));
  }

  Future<void> _openFamilyLeaderboard(BuildContext context) async {
    final jarId = await BackendApi.instance.getLastFamilyJarId();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(initialView: LeaderboardView.family, familyJarId: jarId),
      ),
    );
  }

  Future<void> _openCommunityLeaderboard(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen(initialView: LeaderboardView.global)));
  }

  Future<void> _openStreaks(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StreakScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFEA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0D0BE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(s(40)),
                  bottomRight: Radius.circular(s(40)),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(s(24), s(18), s(24), s(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your giving hub', style: TextStyle(fontSize: s(20), fontWeight: FontWeight.w700, color: const Color(0xFF3C3430))),
                            SizedBox(height: s(2)),
                            Text('Personal, family, and community jars', style: TextStyle(fontSize: s(14), color: const Color(0xFF5A4D43))),
                          ],
                        ),
                        FutureBuilder<StreakInfo>(
                          future: BackendApi.instance.getStreak(),
                          builder: (context, snapshot) {
                            final streak = snapshot.data;
                            return Row(
                              children: [
                                Icon(Icons.local_fire_department, color: const Color(0xFF9B734F), size: s(24)),
                                SizedBox(width: s(3)),
                                Text('${streak?.currentStreak ?? 0}', style: TextStyle(color: const Color(0xFF9B734F), fontSize: s(17), fontWeight: FontWeight.w600)),
                                SizedBox(width: s(14)),
                                Container(
                                  width: s(35),
                                  height: s(35),
                                  decoration: const BoxDecoration(color: Color(0xFFF6F2EB), shape: BoxShape.circle),
                                  child: Icon(Icons.notifications_none, color: Color(0xFF9B886E), size: 19 * scale),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: s(20)),
                    const LiveJarPanel(),
                    SizedBox(height: s(16)),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            scale: scale,
                            title: 'Personal',
                            subtitle: 'Daily giving',
                            icon: Icons.account_balance_wallet_outlined,
                            colors: const [Color(0xFF6FA8CD), Color(0xFF0E6A90)],
                            onTap: () => _openPersonalJar(context),
                          ),
                        ),
                        SizedBox(width: s(14)),
                        Expanded(
                          child: _CategoryCard(
                            scale: scale,
                            title: 'Family',
                            subtitle: 'Shared jar',
                            icon: Icons.groups_2_outlined,
                            colors: const [Color(0xFF2EA1D6), Color(0xFF47B0DF)],
                            onTap: () => _openFamilyLeaderboard(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(14)),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            scale: scale,
                            title: 'Community',
                            subtitle: 'Group impact',
                            icon: Icons.volunteer_activism,
                            colors: const [Color(0xFF6C61A7), Color(0xFF8F86C5)],
                            onTap: () => _openCommunityLeaderboard(context),
                          ),
                        ),
                        SizedBox(width: s(14)),
                        Expanded(
                          child: _CategoryCard(
                            scale: scale,
                            title: 'Streaks',
                            subtitle: 'Consistency focus',
                            icon: Icons.local_fire_department,
                            colors: const [Color(0xFF0A8D8C), Color(0xFF20A0A0)],
                            onTap: () => _openStreaks(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: s(48),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2DEC8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(24))),
                        ),
                        onPressed: onFillJar,
                        child: Text('Drop sadaqah', style: TextStyle(color: const Color(0xFF67594D), fontSize: s(38 / 2), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  SizedBox(width: s(10)),
                  SizedBox(height: s(48), child: OutlinedButton(onPressed: () => onTabChanged(), child: const Text('Open jar'))),
                ],
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: _SectionHeader(scale: scale, title: 'Social / group giving', subtitle: 'Create or join jars and share goals'),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      scale: scale,
                      title: 'Create group jar',
                      subtitle: 'Family or community',
                      icon: Icons.group_add_outlined,
                      onTap: () => _showCreateFamilyJar(context),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: _ActionTile(
                      scale: scale,
                      title: 'Join jar',
                      subtitle: 'Enter an invite code',
                      icon: Icons.meeting_room_outlined,
                      onTap: () => _showJoinFamilyJar(context),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24), vertical: s(8)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchivedJarsScreen()));
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Archived jars'),
                ),
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: FutureBuilder<List<LeaderboardEntry>>(
                future: BackendApi.instance.getFridayLeaderboard(limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _InlineStateCard(message: 'Loading momentum board...');
                  }
                  if (snapshot.hasError) {
                    return _InlineStateCard(message: 'Momentum board unavailable', detail: snapshot.error.toString());
                  }
                  final entries = snapshot.data ?? const <LeaderboardEntry>[];
                  if (entries.isEmpty) {
                    return const _InlineStateCard(
                      message: 'No momentum data yet',
                      detail: 'Your ranking will appear after your first logged act.',
                    );
                  }
                  return _LeaderboardCard(scale: scale, entries: entries);
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: _SectionHeader(scale: scale, title: 'Dashboard', subtitle: 'Real stats from your activity'),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: FutureBuilder<DashboardStats>(
                future: BackendApi.instance.getDashboardStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _InlineStateCard(message: 'Loading dashboard stats...');
                  }
                  if (snapshot.hasError) {
                    return _InlineStateCard(message: 'Dashboard stats unavailable', detail: snapshot.error.toString());
                  }
                  final stats = snapshot.data;
                  if (stats == null || stats.totalActsCompleted == 0) {
                    return const _InlineStateCard(
                      message: 'No activity yet',
                      detail: 'Start logging acts to unlock dashboard metrics.',
                    );
                  }
                  return Column(
                    children: [
                      _MetricStrip(scale: scale, icon: Icons.check_circle_outline, title: 'Acts completed', value: '${stats.totalActsCompleted}', accent: const Color(0xFF0E7276)),
                      SizedBox(height: s(10)),
                      _MetricStrip(scale: scale, icon: Icons.star_outline, title: 'Stars earned', value: '${stats.totalStarsEarned}', accent: const Color(0xFF9B734F)),
                      SizedBox(height: s(10)),
                      _MetricStrip(scale: scale, icon: Icons.groups_2_outlined, title: 'Jars completed', value: '${stats.totalJarsCompleted}', accent: const Color(0xFF6C61A7)),
                      SizedBox(height: s(12)),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                          child: const Text('Open analytics'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: _SectionHeader(scale: scale, title: 'Category snapshot', subtitle: 'Your most active sadaqah categories'),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: FutureBuilder<List<CategoryAnalyticsEntry>>(
                future: BackendApi.instance.getCategoryAnalytics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _InlineStateCard(message: 'Loading category snapshot...');
                  }
                  if (snapshot.hasError) {
                    return _InlineStateCard(message: 'Category analytics unavailable', detail: snapshot.error.toString());
                  }
                  final categories = snapshot.data ?? const <CategoryAnalyticsEntry>[];
                  if (categories.isEmpty) {
                    return const _InlineStateCard(
                      message: 'No category data yet',
                      detail: 'Your category breakdown will appear after a few logged acts.',
                    );
                  }
                  return _CategorySnapshotCard(scale: scale, categories: categories);
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: _SectionHeader(scale: scale, title: 'Personal Impact', subtitle: 'Summary and behavior trends'),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(24)),
              child: FutureBuilder<Map<String, int>>(
                future: BackendApi.instance.getHeatmap(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _InlineStateCard(message: 'Loading activity trend...');
                  }
                  if (snapshot.hasError) {
                    return _InlineStateCard(message: 'Activity trend unavailable', detail: snapshot.error.toString());
                  }
                  final heatmap = snapshot.data ?? const <String, int>{};
                  if (heatmap.isEmpty) {
                    return const _InlineStateCard(
                      message: 'No activity yet',
                      detail: 'Your heatmap will fill in after your first logged act.',
                    );
                  }
                  return _ImpactCard(scale: scale, heatmap: heatmap);
                },
              ),
            ),
            SizedBox(height: s(24)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.scale, required this.title, required this.subtitle});

  final double scale;
  final String title;
  final String subtitle;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: s(19), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28))),
        SizedBox(height: s(4)),
        Text(subtitle, style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52))),
      ],
    );
  }
}

class _InlineStateCard extends StatelessWidget {
  const _InlineStateCard({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2F2A28))),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: const TextStyle(fontSize: 12, color: Color(0xFF6A5E52))),
          ],
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.scale, required this.icon, required this.title, required this.value, required this.accent});

  final double scale;
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
      decoration: BoxDecoration(color: const Color(0xFFF7F3ED), borderRadius: BorderRadius.circular(s(14))),
      child: Row(
        children: [
          Container(
            width: s(40),
            height: s(40),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(s(12))),
            child: Icon(icon, color: accent, size: s(22)),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: s(12), color: const Color(0xFF7A6D60))),
                SizedBox(height: s(2)),
                Text(value, style: TextStyle(fontSize: s(16), color: const Color(0xFF2F2A28), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.scale, required this.title, required this.subtitle, required this.icon, required this.onTap});

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3D5C7),
      borderRadius: BorderRadius.circular(s(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(16)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF8C6A4A), size: s(24)),
              SizedBox(height: s(12)),
              Text(title, style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327))),
              SizedBox(height: s(4)),
              Text(subtitle, style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(12)),
        child: Container(
          height: s(78),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(12)),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontSize: s(15), fontWeight: FontWeight.w700)),
                    SizedBox(height: s(3)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: s(12))),
                  ],
                ),
              ),
              Icon(icon, color: Colors.white, size: s(22)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.scale, required this.entries});

  final double scale;
  final List<LeaderboardEntry> entries;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(color: const Color(0xFFF7F3ED), borderRadius: BorderRadius.circular(s(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Friends / family / weekly board', style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327))),
          SizedBox(height: s(10)),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : s(8)),
              child: Row(
                children: [
                  Container(
                    width: s(28),
                    height: s(28),
                    decoration: BoxDecoration(color: const Color(0xFFE3D5C7), borderRadius: BorderRadius.circular(999)),
                    child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: s(12), fontWeight: FontWeight.w700))),
                  ),
                  SizedBox(width: s(10)),
                  Expanded(child: Text('User #${row.userId}', style: TextStyle(fontSize: s(14), color: const Color(0xFF3B3327)))),
                  Text('${row.stars} stars', style: TextStyle(fontSize: s(13), color: const Color(0xFF7A5B3E), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategorySnapshotCard extends StatelessWidget {
  const _CategorySnapshotCard({required this.scale, required this.categories});

  final double scale;
  final List<CategoryAnalyticsEntry> categories;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(color: const Color(0xFFF7F3ED), borderRadius: BorderRadius.circular(s(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categories.take(4).map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: s(10)),
                  child: _MetricStrip(
                    scale: scale,
                    icon: Icons.category_outlined,
                    title: item.category,
                    value: '${item.count} acts · ${item.stars} stars',
                    accent: const Color(0xFF9B734F),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.scale, required this.heatmap});

  final double scale;
  final Map<String, int> heatmap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final total = heatmap.values.fold<int>(0, (sum, value) => sum + value);
    final busiest = heatmap.entries.isEmpty ? 'No history yet' : heatmap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(color: const Color(0xFFF7F3ED), borderRadius: BorderRadius.circular(s(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total sadaqah tracked', style: TextStyle(fontSize: s(12), color: const Color(0xFF7A6D60))),
          SizedBox(height: s(4)),
          Text('$total acts', style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327))),
          SizedBox(height: s(10)),
          Text('Most active day: $busiest', style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52))),
          SizedBox(height: s(12)),
          Wrap(
            spacing: s(8),
            runSpacing: s(8),
            children: heatmap.entries.take(8).map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(8)),
                decoration: BoxDecoration(color: const Color(0xFFE3D5C7), borderRadius: BorderRadius.circular(999)),
                child: Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: s(12), color: const Color(0xFF3B3327))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}






