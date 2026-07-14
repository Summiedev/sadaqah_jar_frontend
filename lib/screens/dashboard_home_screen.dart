import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../widgets/notification_action_button.dart';
import 'analytics_screen.dart';
import 'archived_jars_screen.dart';
import 'family_jar_detail_screen.dart';
import 'jar_screen.dart';
import 'leaderboard_screen.dart';
import 'notification_center_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key, required this.onFillJar, required this.onNavigateToTab});

  final VoidCallback onFillJar;
  final ValueChanged<int> onNavigateToTab;

  Future<void> _showCreateFamilyJar(BuildContext context) async {
    final nameController = TextEditingController(text: 'Family Jar');
    final capacityController = TextEditingController(text: '33');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return _ActionSheet(
          title: 'Create a family jar',
          subtitle: 'Set a name and capacity, then invite the people you want to share the momentum with.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetField(controller: nameController, label: 'Jar name', hint: 'Ramadan family jar'),
              const SizedBox(height: 12),
              _SheetField(
                controller: capacityController,
                label: 'Capacity',
                hint: '33',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              const _SheetPillRow(pills: ['Invite code', 'Shared streaks', 'Live leaderboard']),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          SnackBar(content: Text('Family jar created with invite code ${response['invite_code'] ?? 'ready'}')),
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

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return _ActionSheet(
          title: 'Join a family jar',
          subtitle: 'Enter the invite code from a family member or friend to jump into the shared board.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetField(controller: inviteController, label: 'Invite code', hint: 'SHARED-1234'),
              const SizedBox(height: 14),
              const _SheetPillRow(pills: ['Live stars', 'Family board', 'Shared wins']),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    try {
      final response = await BackendApi.instance.joinFamilyJar(inviteCode: inviteController.text.trim());
      if (context.mounted) {
        final jarId = (response['jar_id'] as num?)?.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Joined family jar')),
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

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen(initialView: LeaderboardView.global)),
    );
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8D7C1), Color(0xFFD6BE9F), Color(0xFFC7A37A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(s(38)),
                  bottomRight: Radius.circular(s(38)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(s(22), s(18), s(22), s(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(6)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Mizan dashboard',
                                  style: TextStyle(fontSize: s(11), fontWeight: FontWeight.w700, color: const Color(0xFF49361F)),
                                ),
                              ),
                              SizedBox(height: s(10)),
                              Text(
                                'Your giving hub',
                                style: TextStyle(fontSize: s(28), fontWeight: FontWeight.w900, color: const Color(0xFF2F251E), height: 1.02),
                              ),
                              SizedBox(height: s(6)),
                              Text(
                                'Drop sadaqah, watch the jar grow, and keep your family and community momentum visible.',
                                style: TextStyle(fontSize: s(13.5), color: const Color(0xFF5B4D41), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            NotificationActionButton(onPressed: () => _openNotifications(context)),
                            SizedBox(height: s(10)),
                            FutureBuilder<StreakInfo>(
                              future: BackendApi.instance.getStreak(),
                              builder: (context, snapshot) {
                                final streak = snapshot.data?.currentStreak ?? 0;
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(10)),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_fire_department, color: const Color(0xFF7A4E26), size: s(20)),
                                      SizedBox(width: s(6)),
                                      Text(
                                        '$streak',
                                        style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: const Color(0xFF2F251E)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: s(18)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(s(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EE).withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(s(24)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: s(42),
                                height: s(42),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3D5C7),
                                  borderRadius: BorderRadius.circular(s(14)),
                                ),
                                child: Icon(Icons.volunteer_activism_outlined, color: const Color(0xFF8B6842), size: s(22)),
                              ),
                              SizedBox(width: s(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Keep the flow moving',
                                      style: TextStyle(fontSize: s(19), fontWeight: FontWeight.w800, color: const Color(0xFF3B3327)),
                                    ),
                                    SizedBox(height: s(4)),
                                    Text(
                                      'Everything important should be one tap away, from the jar to notifications to family progress.',
                                      style: TextStyle(fontSize: s(13.2), color: const Color(0xFF6A5E52), height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: s(14)),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: s(50),
                                  child: FilledButton(
                                    onPressed: onFillJar,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B6842),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(16))),
                                    ),
                                    child: const Text('Drop sadaqah'),
                                  ),
                                ),
                              ),
                              SizedBox(width: s(10)),
                              Expanded(
                                child: SizedBox(
                                  height: s(50),
                                  child: OutlinedButton(
                                    onPressed: () => onNavigateToTab(1),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF8B6842)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(16))),
                                      foregroundColor: const Color(0xFF3B3327),
                                    ),
                                    child: const Text('Open jar'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: s(16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.48,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: s(12),
                mainAxisSpacing: s(12),
                children: [
                  _HomeQuickCard(
                    scale: scale,
                    title: 'Jar',
                    subtitle: 'Your giving jar',
                    icon: Icons.water_drop_outlined,
                    accent: const Color(0xFF0E7276),
                    onTap: () => _openPersonalJar(context),
                  ),
                  _HomeQuickCard(
                    scale: scale,
                    title: 'Donate',
                    subtitle: 'External donations',
                    icon: Icons.volunteer_activism_outlined,
                    accent: const Color(0xFF8C6A4A),
                    onTap: () => _openCommunityLeaderboard(context),
                  ),
                  _HomeQuickCard(
                    scale: scale,
                    title: 'Streaks',
                    subtitle: 'Momentum and heatmap',
                    icon: Icons.local_fire_department_outlined,
                    accent: const Color(0xFF5C7E52),
                    onTap: () => onNavigateToTab(3),
                  ),
                  _HomeQuickCard(
                    scale: scale,
                    title: 'Profile',
                    subtitle: 'Settings and stats',
                    icon: Icons.person_outline,
                    accent: const Color(0xFF6C61A7),
                    onTap: () => onNavigateToTab(4),
                  ),
                ],
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: Row(
                children: [
                  Expanded(
                    child: _SectionHeader(
                      scale: scale,
                      title: 'Family flow',
                      subtitle: 'Create or join a family jar to unlock shared momentum',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openFamilyLeaderboard(context),
                    icon: const Icon(Icons.groups_2_outlined),
                    label: const Text('Family board'),
                  ),
                ],
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      scale: scale,
                      title: 'Create family jar',
                      subtitle: 'Set capacity and invite code',
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
              padding: EdgeInsets.symmetric(horizontal: s(22), vertical: s(8)),
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
            SizedBox(height: s(8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: _SectionHeader(
                scale: scale,
                title: 'Momentum board',
                subtitle: 'The latest ranked activity, presented as a real board',
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: FutureBuilder<List<LeaderboardEntry>>(
                future: BackendApi.instance.getFridayLeaderboard(limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.trending_up,
                        title: 'Momentum board unavailable',
                        detail: snapshot.error.toString(),
                      ),
                    );
                  }
                  final entries = snapshot.data ?? const <LeaderboardEntry>[];
                  if (entries.isEmpty) {
                    return const _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.leaderboard_outlined,
                        title: 'No momentum data yet',
                        detail: 'Your first logged act will light this board up.',
                      ),
                    );
                  }
                  return _GlassCard(
                    child: Column(
                      children: entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : s(10)),
                          child: Row(
                            children: [
                              Container(
                                width: s(32),
                                height: s(32),
                                decoration: BoxDecoration(
                                  color: index == 0 ? const Color(0xFF8B6842) : const Color(0xFFE3D5C7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: s(12),
                                      fontWeight: FontWeight.w700,
                                      color: index == 0 ? Colors.white : const Color(0xFF3B3327),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: s(10)),
                              Expanded(
                                child: Text(
                                  'User #${row.userId}',
                                  style: TextStyle(fontSize: s(14), color: const Color(0xFF3B3327), fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${row.stars} stars',
                                style: TextStyle(fontSize: s(13), color: const Color(0xFF7A5B3E), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: _SectionHeader(
                scale: scale,
                title: 'Dashboard',
                subtitle: 'Real stats from your activity with a more tactile presentation',
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: FutureBuilder<DashboardStats>(
                future: BackendApi.instance.getDashboardStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  return _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricStrip(
                          scale: scale,
                          icon: Icons.check_circle_outline,
                          title: 'Acts completed',
                          value: '${stats?.totalActsCompleted ?? 0}',
                          accent: const Color(0xFF0E7276),
                        ),
                        SizedBox(height: s(10)),
                        _MetricStrip(
                          scale: scale,
                          icon: Icons.star_outline,
                          title: 'Stars earned',
                          value: '${stats?.totalStarsEarned ?? 0}',
                          accent: const Color(0xFF9B734F),
                        ),
                        SizedBox(height: s(10)),
                        _MetricStrip(
                          scale: scale,
                          icon: Icons.groups_2_outlined,
                          title: 'Jars completed',
                          value: '${stats?.totalJarsCompleted ?? 0}',
                          accent: const Color(0xFF6C61A7),
                        ),
                        SizedBox(height: s(12)),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                            child: const Text('Open analytics'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: _SectionHeader(
                scale: scale,
                title: 'Category snapshot',
                subtitle: 'Your most active sadaqah categories at a glance',
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: FutureBuilder<List<CategoryAnalyticsEntry>>(
                future: BackendApi.instance.getCategoryAnalytics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.category_outlined,
                        title: 'Category analytics unavailable',
                        detail: snapshot.error.toString(),
                      ),
                    );
                  }
                  final categories = snapshot.data ?? const <CategoryAnalyticsEntry>[];
                  if (categories.isEmpty) {
                    return const _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.category_outlined,
                        title: 'No category data yet',
                        detail: 'Once you log a few acts, this section will become a real tracker.',
                      ),
                    );
                  }
                  return _GlassCard(
                    child: Column(
                      children: categories.take(4).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MetricStrip(
                                scale: scale,
                                icon: Icons.category_outlined,
                                title: item.category,
                                value: '${item.count} acts Â· ${item.stars} stars',
                                accent: const Color(0xFF9B734F),
                              ),
                            ),
                          ).toList(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: s(18)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: _SectionHeader(
                scale: scale,
                title: 'Personal impact',
                subtitle: 'Heatmap and behavioral trends with a more polished rhythm',
              ),
            ),
            SizedBox(height: s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(22)),
              child: FutureBuilder<Map<String, int>>(
                future: BackendApi.instance.getHeatmap(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.insights_outlined,
                        title: 'Activity trend unavailable',
                        detail: snapshot.error.toString(),
                      ),
                    );
                  }
                  final heatmap = snapshot.data ?? const <String, int>{};
                  if (heatmap.isEmpty) {
                    return const _GlassCard(
                      child: _EmptyBanner(
                        icon: Icons.calendar_month_outlined,
                        title: 'No activity yet',
                        detail: 'The calendar fills in once you log your first act.',
                      ),
                    );
                  }
                  return _GlassCard(child: _ImpactCard(scale: scale, heatmap: heatmap));
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

class _HomeQuickCard extends StatelessWidget {
  const _HomeQuickCard({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(18)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: s(38),
                height: s(38),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Icon(icon, color: accent, size: s(21)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327))),
                  SizedBox(height: s(2)),
                  Text(subtitle, style: TextStyle(fontSize: s(11.8), color: const Color(0xFF6A5E52))),
                ],
              ),
            ],
          ),
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
        Text(title, style: TextStyle(fontSize: s(19), fontWeight: FontWeight.w800, color: const Color(0xFF2F2A28))),
        SizedBox(height: s(4)),
        Text(subtitle, style: TextStyle(fontSize: s(12.9), color: const Color(0xFF6A5E52))),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE3D5C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF8B6842)),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF2F2A28))),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(fontSize: 12.8, color: Color(0xFF6A5E52), height: 1.4)),
      ],
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
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(s(14)),
      ),
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

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.scale, required this.heatmap});

  final double scale;
  final Map<String, int> heatmap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final total = heatmap.values.fold<int>(0, (sum, value) => sum + value);
    final busiest = heatmap.entries.isEmpty ? 'No history yet' : heatmap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Column(
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
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3ED),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFE3D5C7), borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2F2A28))),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 13.2, color: Color(0xFF6A5E52), height: 1.4)),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2F2A28)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF7A6D60)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3D5C7)),
        ),
      ),
    );
  }
}

class _SheetPillRow extends StatelessWidget {
  const _SheetPillRow({required this.pills});

  final List<String> pills;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills
          .map(
            (pill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3D5C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(pill, style: const TextStyle(fontSize: 12, color: Color(0xFF5A4D43), fontWeight: FontWeight.w600)),
            ),
          )
          .toList(),
    );
  }
}
