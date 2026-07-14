import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../widgets/notification_action_button.dart';
import 'family_jar_detail_screen.dart';
import 'jar_screen.dart';

enum LeaderboardView { global, family, friday, ramadan }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.initialView = LeaderboardView.global, this.familyJarId});

  final LeaderboardView initialView;
  final int? familyJarId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardView _view;
  late Future<int?> _familyJarIdFuture;

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    _familyJarIdFuture = Future<int?>.value(widget.familyJarId).then((value) {
      if (value != null) return value;
      return BackendApi.instance.getLastFamilyJarId();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EBDD),
        surfaceTintColor: Colors.transparent,
        title: const Text('Leaderboard', style: TextStyle(color: Color(0xFF3B3327), fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
        actions: [
          NotificationActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JarScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(s(18), s(14), s(18), s(24)),
        children: [
          Container(
            padding: EdgeInsets.all(s(16)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8D7C1), Color(0xFFF7F3ED)],
              ),
              borderRadius: BorderRadius.circular(s(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rankings that feel alive', style: TextStyle(fontSize: s(22), fontWeight: FontWeight.w900, color: const Color(0xFF2F251E))),
                SizedBox(height: s(5)),
                Text('Switch between global, family, momentum, and Ramadan views without losing the visual thread.', style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52), height: 1.4)),
              ],
            ),
          ),
          SizedBox(height: s(16)),
          _ViewSelector(
            scale: scale,
            current: _view,
            onSelected: (view) => setState(() => _view = view),
          ),
          SizedBox(height: s(16)),
          FutureBuilder<RankSummary>(
            future: BackendApi.instance.getMyRank(),
            builder: (context, snapshot) {
              final rank = snapshot.data;
              return _SummaryCard(
                scale: scale,
                title: 'Your standing',
                leftLabel: 'Global',
                leftValue: rank?.globalRank != null ? '#${rank!.globalRank}' : '-',
                rightLabel: 'Stars',
                rightValue: '${rank?.globalScore ?? 0}',
                subtitle: 'Ramadan: ${rank?.ramadanRank != null ? '#${rank!.ramadanRank}' : '-'}',
              );
            },
          ),
          SizedBox(height: s(16)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _LeaderboardBody(
              key: ValueKey(_view),
              view: _view,
              scale: scale,
              familyJarIdFuture: _familyJarIdFuture,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.scale, required this.current, required this.onSelected});

  final double scale;
  final LeaderboardView current;
  final ValueChanged<LeaderboardView> onSelected;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<LeaderboardView, String>>[
      const MapEntry(LeaderboardView.global, 'Global'),
      const MapEntry(LeaderboardView.family, 'Family'),
      const MapEntry(LeaderboardView.friday, 'Momentum'),
      const MapEntry(LeaderboardView.ramadan, 'Ramadan'),
    ];

    return Wrap(
      spacing: s(8),
      runSpacing: s(8),
      children: items.map((item) {
        final selected = item.key == current;
        return Material(
          color: selected ? const Color(0xFF8B6842) : const Color(0xFFF7F3ED),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(item.key),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(10)),
              child: Text(
                item.value,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF3B3327),
                  fontWeight: FontWeight.w700,
                  fontSize: s(13),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.scale,
    required this.title,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.subtitle,
  });

  final double scale;
  final String title;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String subtitle;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(s(18)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: const Color(0xFF3B3327))),
          SizedBox(height: s(12)),
          Row(
            children: [
              Expanded(child: _StatBlock(scale: scale, label: leftLabel, value: leftValue)),
              SizedBox(width: s(10)),
              Expanded(child: _StatBlock(scale: scale, label: rightLabel, value: rightValue)),
            ],
          ),
          SizedBox(height: s(10)),
          Text(subtitle, style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.scale, required this.label, required this.value});

  final double scale;
  final String label;
  final String value;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(s(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
          SizedBox(height: s(4)),
          Text(value, style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w800, color: const Color(0xFF3B3327))),
        ],
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({super.key, required this.view, required this.scale, required this.familyJarIdFuture});

  final LeaderboardView view;
  final double scale;
  final Future<int?> familyJarIdFuture;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    switch (view) {
      case LeaderboardView.global:
        return _LeaderboardList(
          scale: scale,
          title: 'Global rankings',
          subtitle: 'Everyone using the app across all active jars.',
          future: BackendApi.instance.getGlobalLeaderboard(limit: 20),
        );
      case LeaderboardView.friday:
        return _LeaderboardList(
          scale: scale,
          title: 'Momentum rankings',
          subtitle: 'This week\'s consistency snapshot.',
          future: BackendApi.instance.getFridayLeaderboard(limit: 20),
        );
      case LeaderboardView.ramadan:
        return _LeaderboardList(
          scale: scale,
          title: 'Ramadan rankings',
          subtitle: 'Focused on consistency and habit streaks.',
          future: BackendApi.instance.getRamadanLeaderboard(),
        );
      case LeaderboardView.family:
        return FutureBuilder<int?>(
          future: familyJarIdFuture,
          builder: (context, snapshot) {
            final jarId = snapshot.data;
            if (jarId == null) {
              return _EmptyFamilyState(scale: scale);
            }

            return Column(
              children: [
                _LeaderboardList(
                  scale: scale,
                  title: 'Family rankings',
                  subtitle: 'Your saved family jar leaderboard.',
                  future: BackendApi.instance.getFamilyLeaderboard(jarId: jarId, limit: 20),
                ),
                SizedBox(height: s(14)),
                FutureBuilder<Map<String, dynamic>>(
                  future: BackendApi.instance.getFamilyTopContributor(jarId: jarId),
                  builder: (context, contributorSnapshot) {
                    final contributor = contributorSnapshot.data;
                    final userId = (contributor?['user_id'] as num?)?.toInt();
                    final stars = (contributor?['stars'] as num?)?.toInt() ?? 0;
                    return _SummaryCard(
                      scale: scale,
                      title: 'Top contributor',
                      leftLabel: 'User',
                      leftValue: userId != null ? 'User #$userId' : '-',
                      rightLabel: 'Stars',
                      rightValue: '$stars',
                      subtitle: 'Open the family detail view for the live jar board.',
                    );
                  },
                ),
                SizedBox(height: s(12)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: jarId)),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open family detail'),
                  ),
                ),
              ],
            );
          },
        );
    }
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.scale, required this.title, required this.subtitle, required this.future});

  final double scale;
  final String title;
  final String subtitle;
  final Future<List<LeaderboardEntry>> future;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: future,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(s(16)),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3ED),
            borderRadius: BorderRadius.circular(s(18)),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: const Color(0xFF3B3327))),
              SizedBox(height: s(4)),
              Text(subtitle, style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
              SizedBox(height: s(12)),
              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (entries == null || entries.isEmpty)
                _EmptyBoard(scale: scale, title: 'No board data yet', detail: 'Once the app has activity, this leaderboard will start showing real names and scores.')
              else
                ...entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : s(8)),
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
                          child: Text('User #${row.userId}', style: TextStyle(fontSize: s(14), color: const Color(0xFF3B3327))),
                        ),
                        Text('${row.stars} stars', style: TextStyle(fontSize: s(13), color: const Color(0xFF7A5B3E), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyFamilyState extends StatelessWidget {
  const _EmptyFamilyState({required this.scale});

  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(18)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(s(18)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE3D5C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_2_outlined, color: Color(0xFF8B6842)),
          ),
          SizedBox(height: s(12)),
          Text('No family jar saved yet.', style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w800, color: const Color(0xFF3B3327))),
          SizedBox(height: s(6)),
          Text('Create or join a family jar first, then the family rankings will show up here.', style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52))),
          SizedBox(height: s(12)),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JarScreen()));
            },
            child: const Text('Create or join family jar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.scale, required this.title, required this.detail});

  final double scale;
  final String title;
  final String detail;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(s(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: s(14), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28))),
          SizedBox(height: s(4)),
          Text(detail, style: TextStyle(fontSize: s(12.5), color: const Color(0xFF6A5E52), height: 1.35)),
        ],
      ),
    );
  }
}