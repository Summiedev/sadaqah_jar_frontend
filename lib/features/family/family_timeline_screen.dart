import 'package:flutter/material.dart';

import 'family_models.dart';
import 'family_theme.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({required this.id, super.key});

  final String id;

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  late final Future<void> _load = Future<void>.value();
  FamilyJar? _jar;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _load,
          builder: (context, snap) {
            final groups = jar == null ? <_DayGroup>[] : _buildGroups(jar);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ScreenHeader(
                      title: 'Activity',
                      subtitle: jar == null ? null : 'Quiet moments from ${jar.name}',
                    ),
                  ),
                ),
                if (snap.connectionState != ConnectionState.done)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20))))))
                else if (groups.isEmpty)
                  const SliverFillRemaining(child: _EmptyTimeline())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final g = groups[index];
                          return _DaySection(group: g);
                        },
                        childCount: groups.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_DayGroup> _buildGroups(FamilyJar jar) {
    return [
      _DayGroup('Today', [
        _Activity(Icons.auto_awesome_outlined, fOlive, 'Hafsa shared a reflection.'),
        _Activity(Icons.favorite_border_outlined, fBronze, 'Omar logged an act of charity.'),
        _Activity(Icons.visibility_off_outlined, fStoneLight, 'A family member completed a private act of charity.'),
      ]),
      _DayGroup('Yesterday', [
        _Activity(Icons.wb_sunny_outlined, fBronze, 'Fatimah completed Morning Adhkar.'),
        _Activity(Icons.flag_outlined, fOlive, 'The family reached 75% of this month\'s goal.'),
        _Activity(Icons.menu_book_outlined, fBronzeDark, 'Yusuf shared a weekly reflection.'),
      ]),
      _DayGroup('This week', [
        _Activity(Icons.volunteer_activism_outlined, fOlive, 'Aisha helped a neighbour.'),
        _Activity(Icons.visibility_off_outlined, fStoneLight, 'A family member completed a private act of charity.'),
        _Activity(Icons.groups_outlined, fBronze, 'Maryam encouraged the family with a kind note.'),
      ]),
    ];
  }
}

class _DayGroup {
  _DayGroup(this.day, this.items);
  final String day;
  final List<_Activity> items;
}

class _Activity {
  _Activity(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group});

  final _DayGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: fBronze, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(group.day.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: fBronzeDark)),
            ],
          ),
        ),
        SoftCard(
          padding: const EdgeInsets.all(6),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: fClayLight, indent: 52),
            itemBuilder: (context, index) {
              final a = group.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(a.icon, size: 18, color: a.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.text,
                        style: const TextStyle(fontSize: 13.5, height: 1.45, color: fWalnut),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
            child: const Center(child: Icon(Icons.timeline_outlined, size: 38, color: fBronze)),
          ),
          const SizedBox(height: 18),
          const Text('No activity yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('As your family gives, remembers, and reflects, gentle moments will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        ],
      ),
    );
  }
}
