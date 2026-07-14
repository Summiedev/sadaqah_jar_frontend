import 'package:flutter/material.dart';

import '../shared/prototype_skeleton.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 700));
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: PrototypeSkeleton(
                  children: [
                    SkeletonLine(width: 140, height: 12),
                    SizedBox(height: 14),
                    SkeletonLine(width: double.infinity, height: 42, radius: 16),
                    SizedBox(height: 14),
                    SkeletonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 170, height: 15),
                          SizedBox(height: 12),
                          SkeletonLine(width: double.infinity, height: 74, radius: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: _JourneyHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E7DB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3D3C3)),
                      ),
                      child: TabBar(
                        onTap: (index) => setState(() => _tab = index),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        labelColor: const Color(0xFF2F241E),
                        unselectedLabelColor: const Color(0xFF9A8A7A),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Reflections'),
                          Tab(text: 'Adhkar'),
                          Tab(text: 'Goals'),
                          Tab(text: 'Analytics'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'LOCAL DEVICE ENCRYPTED',
                        style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF2F241E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ReflectionsPanel(active: _tab == 0),
                        const _AdhkarPanel(),
                        const _GoalsPanel(),
                        const _AnalyticsPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MIZAN • Journey',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2F241E)),
        ),
        Row(
          children: [
            Text(
              'RAMADAN MODE',
              style: TextStyle(fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: Color(0xFFB38964)),
            ),
            SizedBox(width: 10),
            Icon(Icons.nights_stay_outlined, size: 18, color: Color(0xFFB38964)),
          ],
        ),
      ],
    );
  }
}

class _ReflectionsPanel extends StatelessWidget {
  const _ReflectionsPanel({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: const [
        _WeeklySummaryCard(),
        SizedBox(height: 14),
        _SectionHeader(title: 'PAST REFLECTIONS', action: 'Log Reflection'),
        SizedBox(height: 14),
        _ReflectionCard(
          title: 'PEACEFUL',
          date: 'Jul 9, 2026',
          badge: 'Sincere Joy',
          prompt: 'Niyyah: "To foster connection and bring ease to our household"',
          body: 'Prepared morning breakfast silently for my parents before they woke. Experienced a quiet, peaceful happiness in doing a task without seeking any verbal recognition.',
          insight: 'Insight: Charity begins at home with quiet service.',
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEKLY SUMMARY INSIGHTS', style: TextStyle(fontSize: 12, letterSpacing: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
          SizedBox(height: 12),
          Text(
            'Your reflections show a prevailing mood of peacefulness and gratitude. You logged 2 key acts of silent worship. The deliberate practice of niyyah has grounded your interactions this week.',
            style: TextStyle(fontSize: 12, height: 1.55, fontStyle: FontStyle.italic, color: Color(0xFF5F4D40)),
          ),
          SizedBox(height: 14),
          Divider(height: 1, color: Color(0xFFE8DCCA)),
          SizedBox(height: 12),
          Text('Encrypted locally. No summaries ever leave this phone.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF2F241E))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
        Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB06B45))),
      ],
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.title, required this.date, required this.badge, required this.prompt, required this.body, required this.insight});

  final String title;
  final String date;
  final String badge;
  final String prompt;
  final String body;
  final String insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: Color(0xFF2F241E))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE3D3C3)),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 10, color: Color(0xFF2F241E))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 2, height: 54, color: const Color(0xFF2F241E).withValues(alpha: .8)),
          const SizedBox(height: 8),
          Text(prompt, style: const TextStyle(fontSize: 12, height: 1.45, fontStyle: FontStyle.italic, color: Color(0xFF5F4D40))),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 12, height: 1.55, color: Color(0xFF2F241E))),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3F2F24)),
            ),
            child: Text(insight, style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
          ),
        ],
      ),
    );
  }
}

class _AdhkarPanel extends StatelessWidget {
  const _AdhkarPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Adhkar Book coming soon', style: TextStyle(color: Color(0xFF6D5B4D))));
  }
}

class _GoalsPanel extends StatelessWidget {
  const _GoalsPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Goals panel coming soon', style: TextStyle(color: Color(0xFF6D5B4D))));
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Analytics panel coming soon', style: TextStyle(color: Color(0xFF6D5B4D))));
  }
}
