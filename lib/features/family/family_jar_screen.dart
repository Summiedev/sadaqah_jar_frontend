import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'family_models.dart';
import 'family_theme.dart';
import 'member_profile_sheet.dart';

class FamilyJarScreen extends StatefulWidget {
  const FamilyJarScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilyJarScreen> createState() => _FamilyJarScreenState();
}

class _FamilyJarScreenState extends State<FamilyJarScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 450));
  FamilyJar? _jar;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_jar == null) {
      return const Scaffold(backgroundColor: fIvory, body: Center(child: Text('Family not found', style: TextStyle(color: fStone))));
    }
    final jar = _jar!;
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(backgroundColor: fIvory, body: Center(child: SizedBox(width: 150, height: 180, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(40)))))));
        }
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: fIvory,
            body: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: fIvory,
                  foregroundColor: fWalnutLight,
                  centerTitle: true,
                  title: Text(jar.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                  leading: _ShellButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => context.pop(),
                  ),
                  actions: [
                    _ShellButton(
                      icon: Icons.notifications_none_outlined,
                      onTap: () {},
                      badge: true,
                    ),
                    const SizedBox(width: 8),
                  ],
                  expandedHeight: 188,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _Banner(jar: jar),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(58),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: fClayPale,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: fClay),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        labelColor: fWalnut,
                        unselectedLabelColor: fStoneLight,
                        labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Activity'),
                          Tab(text: 'Reflections'),
                          Tab(text: 'Du\u2019a'),
                          Tab(text: 'Goals'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OverviewTab(jar: jar),
                  _ActivityTab(jar: jar),
                  _ReflectionsTab(jar: jar),
                  _PrayersTab(jar: jar),
                  _GoalsTab(jar: jar),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// HEADER BANNER
class _Banner extends StatelessWidget {
  const _Banner({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fClayPale, fIvory],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 56),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: fWhite,
              shape: BoxShape.circle,
              border: Border.all(color: fClay, width: 1.5),
              boxShadow: const [BoxShadow(color: fShadow, blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Center(child: Text(jar.coverEmoji, style: const TextStyle(fontSize: 38))),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_outlined, size: 13, color: fStoneLight),
              const SizedBox(width: 5),
              Text('${jar.memberCount} members', style: const TextStyle(fontSize: 11.5, color: fStoneLight)),
              const SizedBox(width: 12),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: fStonePale, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(jar.goalLabel, style: const TextStyle(fontSize: 11.5, color: fStoneLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShellButton extends StatelessWidget {
  const _ShellButton({required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 8),
      child: Material(
        color: fWhite,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: fClay)),
                child: Icon(icon, size: 16, color: fWalnutLight),
              ),
              if (badge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: fOlive, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: fWhite, width: 1.5)))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// TAB 1 â€” OVERVIEW
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _JarCluster(jar: jar),
        const SizedBox(height: 10),
        _StatsRow(jar: jar),
        const SizedBox(height: 22),
        const SectionLabel('Members'),
        const SizedBox(height: 12),
        _MembersRow(jar: jar),
        const SizedBox(height: 24),
        MizanButton(label: 'Invite family', onTap: () => context.push('/family/invitations')),
        const SizedBox(height: 10),
        MizanOutlineButton(label: 'Manage jar', onTap: () => context.push('/family/settings/${jar.id}')),
      ],
    );
  }
}

// JAR CLUSTER
class _JarCluster extends StatelessWidget {
  const _JarCluster({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    final maxAround = math.min(jar.members.length, 8);
    final overflow = jar.members.length - maxAround;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, 320).toDouble();
        final avatar = 48.0;
        final radius = side / 2 - avatar / 2 - 12;
        final cx = side / 2;
        final cy = side / 2;
        final jarSize = side * 0.56;

        final avatars = <Widget>[];
        for (int i = 0; i < maxAround; i++) {
          final m = jar.members[i];
          final angle = -math.pi / 2 + i * (2 * math.pi / maxAround);
          final x = cx + radius * math.cos(angle) - avatar / 2;
          final y = cy + radius * math.sin(angle) - avatar / 2;
          avatars.add(
            Positioned(
              left: x,
              top: y,
              child: _AvatarButton(member: m, size: avatar),
            ),
          );
        }

        return SizedBox(
          height: side + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(child: _GlowDrop(jarSize: jarSize, fill: jar.progress)),
              ...avatars,
              if (overflow > 0)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: fWhite, borderRadius: BorderRadius.circular(999), border: Border.all(color: fBronze)),
                    child: Text('+$overflow', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fBronze)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarButton extends StatefulWidget {
  const _AvatarButton({required this.member, required this.size});

  final FamilyMember member;
  final double size;

  @override
  State<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<_AvatarButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _a = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _a,
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) => _c.reverse(),
        onTapCancel: () => _c.reverse(),
        onTap: () => showMemberProfile(context, widget.member),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MizanAvatar(name: widget.member.name, accent: widget.member.accent, size: widget.size, contributed: widget.member.contributedToday),
            const SizedBox(height: 3),
            SizedBox(
              width: widget.size + 6,
              child: Text(
                widget.member.name.split(' ').first,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, color: fWalnutLight, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowDrop extends StatefulWidget {
  const _GlowDrop({required this.jarSize, required this.fill});

  final double jarSize;
  final double fill;

  @override
  State<_GlowDrop> createState() => _GlowDropState();
}

class _GlowDropState extends State<_GlowDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _fall = Tween<double>(begin: -1.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));
  late final Animation<double> _fade = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final yOffset = _fall.value * widget.jarSize * 0.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _fade.value,
              child: Transform.translate(
                offset: Offset(0, yOffset),
                child: Container(
                  width: 10,
                  height: 16,
                  decoration: BoxDecoration(
                    color: fBronzeLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(3)),
                    boxShadow: [BoxShadow(color: fBronzeLight.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                ),
              ),
            ),
            FamilyJarView(fill: widget.fill, size: widget.jarSize, glow: 0.5),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Progress', '${(jar.progress * 100).round()}%'),
      ('Days left', '${jar.daysRemaining}'),
      ('Members', '${jar.memberCount}'),
      ('Goal', jar.goalLabel),
    ];
    return Row(
      children: items.map((it) {
        final i = items.indexOf(it);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                children: [
                  Text(it.$1.toUpperCase(), style: const TextStyle(fontSize: 8.5, letterSpacing: 1, fontWeight: FontWeight.w700, color: fStonePale)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(it.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MembersRow extends StatelessWidget {
  const _MembersRow({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jar.members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final m = jar.members[index];
          return GestureDetector(
            onTap: () => showMemberProfile(context, m),
            child: Column(
              children: [
                MizanAvatar(name: m.name, accent: m.accent, size: 46, contributed: m.contributedToday),
                const SizedBox(height: 4),
                SizedBox(
                  width: 52,
                  child: Text(m.name.split(' ').first, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: fWalnutLight, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// TAB 2 â€” ACTIVITY
class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.jar});

  final FamilyJar jar;

  List<_DayGroup> get _groups => [
    _DayGroup('Today', [
      _Activity(Icons.auto_awesome_outlined, fOlive, 'Hafsa shared a reflection.'),
      _Activity(Icons.favorite_border_outlined, fBronze, 'Omar logged an act of charity.'),
      _Activity(Icons.visibility_off_outlined, fStoneLight, 'A family member completed a private act of charity.'),
    ]),
    _DayGroup('Yesterday', [
      _Activity(Icons.wb_sunny_outlined, fBronze, 'Fatimah completed Morning Adhkar.'),
      _Activity(Icons.flag_outlined, fOlive, 'The family reached 75% of this month\u2019s goal.'),
      _Activity(Icons.menu_book_outlined, fBronzeDark, 'Yusuf shared a weekly reflection.'),
    ]),
    _DayGroup('This week', [
      _Activity(Icons.volunteer_activism_outlined, fOlive, 'Aisha helped a neighbour.'),
      _Activity(Icons.visibility_off_outlined, fStoneLight, 'A family member completed a private act of charity.'),
      _Activity(Icons.groups_outlined, fBronze, 'Maryam encouraged the family with a kind note.'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) {
      return const Center(child: Text('No activity yet', style: TextStyle(color: fStone)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: groups.length,
      itemBuilder: (context, i) => _DaySection(group: groups[i]),
    );
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
                    Expanded(child: Text(a.text, style: const TextStyle(fontSize: 13.5, height: 1.45, color: fWalnut))),
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

// TAB 3 â€” REFLECTIONS
class _ReflectionsTab extends StatefulWidget {
  const _ReflectionsTab({required this.jar});

  final FamilyJar jar;

  @override
  State<_ReflectionsTab> createState() => _ReflectionsTabState();
}

class _FReflection {
  _FReflection(this.author, this.authorAccent, this.text, this.time);
  final String author;
  final Color authorAccent;
  final String text;
  final String time;
  final Map<String, int> encouragement = <String, int>{
    'May Allah accept': 0,
    'Ameen': 0,
    'Barakallahu feek': 0,
  };
}

class _ReflectionsTabState extends State<_ReflectionsTab> {
  final List<_FReflection> _reflections = [];
  final TextEditingController _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reflections.addAll([
      _FReflection('Fatimah Ahmad', fOlive, 'Alhamdulillah for another week together.', '2h'),
      _FReflection('Yusuf Ahmad', fBronze, 'May Allah accept our efforts this month.', '5h'),
      _FReflection('Maryam Ahmad', fBronzeDark, 'Grateful we could help someone today.', 'Yesterday'),
      _FReflection('Hafsa Ahmad', fOlive, 'Small things, done with love, are never small.', 'Yesterday'),
    ]);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _reflections.insert(0, _FReflection('You', fBronze, t, 'now'));
      _c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _reflections.isEmpty
              ? const _EmptyState(icon: Icons.menu_book_outlined, title: 'No reflections yet', body: 'Share your first reflection. No replies â€” only quiet encouragement.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: _reflections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ReflectionCard(
                    r: _reflections[index],
                    onPick: (k) => setState(() => _reflections[index].encouragement[k] = (_reflections[index].encouragement[k] ?? 0) + 1),
                  ),
                ),
        ),
        _ComposeBar(controller: _c, hint: 'Share a quiet reflection\u2026', onSend: _add),
      ],
    );
  }
}

const List<String> _encourageOptions = <String>['May Allah accept', 'Ameen', 'Barakallahu feek'];

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.r, required this.onPick});

  final _FReflection r;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.authorAccent, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
                    Text(r.time, style: const TextStyle(fontSize: 10.5, color: fStoneLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('\u201C${r.text}\u201D', style: const TextStyle(fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic, color: fWalnut)),
          const SizedBox(height: 14),
          const Divider(height: 1, color: fClayLight),
          const SizedBox(height: 12),
          const Text('Offer gentle encouragement', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: fStonePale)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _encourageOptions.map((k) {
              final count = r.encouragement[k] ?? 0;
              return Material(
                color: count > 0 ? r.authorAccent.withValues(alpha: 0.12) : fWhite,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onPick(k),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: count > 0 ? r.authorAccent : fClay)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(k, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: count > 0 ? r.authorAccent : fStone))),
                        if (count > 0) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: r.authorAccent, borderRadius: BorderRadius.circular(999)),
                            child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fWhite)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// TAB 4 â€” DU'A (PRAYER REQUESTS)
class _PrayersTab extends StatefulWidget {
  const _PrayersTab({required this.jar});

  final FamilyJar jar;

  @override
  State<_PrayersTab> createState() => _PrayersTabState();
}

class _PRequest {
  _PRequest(this.author, this.accent, this.text, this.time);
  final String author;
  final Color accent;
  final String text;
  final String time;
  int ameen = 0;
  int ease = 0;
  int accept = 0;
}

class _PrayersTabState extends State<_PrayersTab> {
  final List<_PRequest> _requests = [];
  final TextEditingController _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requests.addAll([
      _PRequest('Fatimah Ahmad', fOlive, 'Please remember my exams in your du\u2019a.', '1h'),
      _PRequest('Yusuf Ahmad', fBronze, 'Please pray for my parents.', '4h'),
      _PRequest('Maryam Ahmad', fBronzeDark, 'Please remember our family this Friday.', 'Yesterday'),
    ]);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _requests.insert(0, _PRequest('You', fBronze, t, 'now'));
      _c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _requests.isEmpty
              ? const _EmptyState(icon: Icons.favorite_border_outlined, title: 'No prayer requests', body: 'Support one another through du\u2019a. Share a request and let your family hold you close.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _RequestCard(key: ValueKey(index), r: _requests[index]),
                ),
        ),
        _ComposeBar(controller: _c, hint: 'Request a private du\u2019a\u2026', onSend: _add),
      ],
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.r, super.key});

  final _PRequest r;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return SoftCard(
      color: fClayPale,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.accent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fWalnut)),
                    Text(r.time, style: const TextStyle(fontSize: 10.5, color: fStoneLight)),
                  ],
                ),
              ),
              const Icon(Icons.favorite_border_outlined, size: 16, color: fBronze),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.text, style: const TextStyle(fontSize: 14, height: 1.5, color: fWalnut)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResponseChip(label: 'Ameen', active: r.ameen > 0, onTap: () => setState(() => r.ameen++)),
              _ResponseChip(label: 'May Allah grant ease', active: r.ease > 0, onTap: () => setState(() => r.ease++)),
              _ResponseChip(label: 'May Allah accept', active: r.accept > 0, onTap: () => setState(() => r.accept++)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseChip extends StatefulWidget {
  const _ResponseChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_ResponseChip> createState() => _ResponseChipState();
}

class _ResponseChipState extends State<_ResponseChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  late final Animation<double> _a = Tween<double>(begin: 1, end: 0.92).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  bool _tapped = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active || _tapped;
    return ScaleTransition(
      scale: _a,
      child: Material(
        color: active ? fBronze.withValues(alpha: 0.12) : fWhite,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTapDown: (_) => _c.forward(),
          onTapUp: (_) => _c.reverse(),
          onTapCancel: () => _c.reverse(),
          onTap: () {
            setState(() => _tapped = true);
            widget.onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: active ? fBronze : fClay)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? fBronze : fStone)),
                if (active) const SizedBox(width: 6),
                if (active) const Icon(Icons.check, size: 12, color: fBronze),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TAB 5 â€” GOALS
class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    final goals = jar.goals;
    if (goals.isEmpty) {
      return const _EmptyState(icon: Icons.flag_outlined, title: 'No goals yet', body: 'Create a gentle intention your family can grow toward â€” together, one act at a time.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _GoalCard(goal: goals[index]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final FamilyGoal goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: goal.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.flag_outlined, size: 20, color: goal.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                    const SizedBox(height: 3),
                    Text(goal.subtitle, style: const TextStyle(fontSize: 11.5, color: fStoneLight)),
                  ],
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: goal.accent, fontFamily: 'Georgia')),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(height: 10, decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.circular(99))),
              FractionallySizedBox(
                widthFactor: goal.progress.clamp(0.0, 1.0),
                child: Container(height: 10, decoration: BoxDecoration(color: goal.accent, borderRadius: BorderRadius.circular(99))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${goal.actsDone} of ${goal.actsTarget} gentle acts offered', style: const TextStyle(fontSize: 11.5, color: fStone)),
        ],
      ),
    );
  }
}

// SHARED HELPERS
class _ComposeBar extends StatelessWidget {
  const _ComposeBar({required this.controller, required this.hint, required this.onSend});

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(color: fSurface, border: Border(top: BorderSide(color: fClay))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: fWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: fClay)),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 13.5, height: 1.45, color: fWalnut),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: fStonePale, fontStyle: FontStyle.italic),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: fBronze,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSend,
              child: const SizedBox(width: 46, height: 46, child: Icon(Icons.send_outlined, size: 18, color: fWhite)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
            child: Center(child: Icon(icon, size: 38, color: fBronze)),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
      ],
    );
  }
}
