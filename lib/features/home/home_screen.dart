import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../shared/prototype_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 750));

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: PrototypeSkeleton(
                  children: [
                    SkeletonLine(width: 120, height: 12),
                    SizedBox(height: 16),
                    SkeletonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 150, height: 12),
                          SizedBox(height: 12),
                          SkeletonLine(width: double.infinity, height: 48, radius: 18),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    SkeletonCard(
                      child: Column(
                        children: [
                          SkeletonLine(width: 180, height: 180, radius: 90),
                          SizedBox(height: 12),
                          SkeletonLine(width: 220, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(onAdd: () => context.push('/add-act'), mode: mode),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    children: [
                      _GreetingRow(mode: mode),
                      const SizedBox(height: 14),
                      _HeroJarCard(),
                      const SizedBox(height: 14),
                      _PrimaryAction(mode: mode),
                      const SizedBox(height: 14),
                      _QuickLinks(mode: mode),
                      const SizedBox(height: 14),
                      _InsightsCard(mode: mode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onAdd, required this.mode});

  final VoidCallback onAdd;
  final int mode;

  @override
  Widget build(BuildContext context) {
    final modeLabel = mode == kModeFamily ? 'Family' : mode == kModePersonal ? 'Sanctuary' : 'Sanctuary';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F0E8),
        border: Border(bottom: BorderSide(color: Color(0xFFE3D3C3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF8B6842)),
              const SizedBox(width: 8),
              Text(modeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
            ],
          ),
          Row(
            children: [
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline), color: const Color(0xFF8B6842), visualDensity: VisualDensity.compact),
              IconButton(onPressed: () {}, icon: const Icon(Icons.sunny_snowing), color: const Color(0xFF8B6842), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    final eyebrow = mode == kModeFamily ? 'MIZAN Â· FAMILY' : 'MIZAN Â· SANCTUARY';
    final greeting = mode == kModeFamily ? 'Peace be with you, gentle family' : 'Peace be with you, sincere seeker';
    final pillLabel = mode == kModeFamily ? 'Growing together' : '3 Days Consistency';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: Color(0xFF9A8A7A))),
              const SizedBox(height: 4),
              Text(greeting, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E1CF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE0C6AE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, size: 16, color: Color(0xFF8B6842)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pillLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                  const Text('Mizan', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Color(0xFF9A8A7A))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroJarCard extends StatelessWidget {
  const _HeroJarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2EB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6D7C8)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 196,
                  height: 196,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 2.4,
                    backgroundColor: const Color(0xFFE9DDD0),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Colors.white, Color(0xFFE9D7C4)]),
                    border: Border.all(color: const Color(0xFFD6BEA8), width: 6),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: const Icon(Icons.local_fire_department, size: 64, color: Color(0xFF8B6842)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap the jar for a quiet word', style: TextStyle(fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: Color(0xFFA28F7F))),
          const SizedBox(height: 10),
          const Text(
            '"A warm, sincere smile is a quiet charity for another soul."',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, fontStyle: FontStyle.italic, color: Color(0xFF5F4D40)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F4ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6D7C8)),
              ),
              child: const Text('Daily Devotions: 3/3', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Color(0xFF8B6842), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    final label = mode == kModeFamily
        ? 'Add a family act'
        : mode == kModePersonal
            ? 'Record an act of generosity'
            : 'Record an act';
    return FilledButton(
      onPressed: () => context.push('/add-act'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4E3629),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    final links = mode == kModeFamily
        ? <(String, String, IconData, Color)>[
            ('Family Courtyard', 'Household Jars', Icons.groups_outlined, const Color(0xFF749B75)),
            ('Household Goals', 'Daily Milestones', Icons.track_changes_outlined, const Color(0xFF8B6842)),
            ('Create Jar', 'Set Up Devotion', Icons.add, const Color(0xFFC28A53)),
          ]
        : mode == kModePersonal
            ? <(String, String, IconData, Color)>[
            ('Sanctuary Oasis', 'Communal Well', Icons.auto_awesome_outlined, const Color(0xFF4B77C4)),
            ('Create Jar', 'Set Up Devotion', Icons.add, const Color(0xFFC28A53)),
            ('Household Goals', 'Daily Milestones', Icons.track_changes_outlined, const Color(0xFF8B6842)),
          ]
            : <(String, String, IconData, Color)>[
            ('Family Courtyard', 'Household Jars', Icons.groups_outlined, const Color(0xFF749B75)),
            ('Sanctuary Oasis', 'Communal Well', Icons.auto_awesome_outlined, const Color(0xFF4B77C4)),
            ('Create Jar', 'Set Up Devotion', Icons.add, const Color(0xFFC28A53)),
            ('Household Goals', 'Daily Milestones', Icons.track_changes_outlined, const Color(0xFF8B6842)),
          ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E9DE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Links', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: Color(0xFFA28F7F), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: links.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.55,
            ),
            itemBuilder: (context, index) {
              final link = links[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3D3C3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: link.$4.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(link.$3, size: 16, color: link.$4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(link.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                          Text(link.$2, style: const TextStyle(fontSize: 8, color: Color(0xFF9A8A7A))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    final title = mode == kModeFamily ? 'Family Snapshot' : 'Snapshot';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
          const SizedBox(height: 10),
          const _MetricRow(icon: Icons.check_circle_outline, label: 'Acts completed', value: '12'),
          const SizedBox(height: 8),
          const _MetricRow(icon: Icons.star_outline, label: 'Stars earned', value: '24'),
          const SizedBox(height: 8),
          const _MetricRow(icon: Icons.groups_2_outlined, label: 'Jars completed', value: '4'),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: const Color(0xFFE8D8C7), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF8B6842), size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2F241E)))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8B6842))),
      ],
    );
  }
}
