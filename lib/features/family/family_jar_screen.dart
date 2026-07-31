import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/add_act_screen.dart';
import 'family_theme.dart';
import '../../services/backend_api.dart';

class FamilyJarScreen extends StatefulWidget {
  const FamilyJarScreen({required this.id, super.key});
  final String id;

  @override
  State<FamilyJarScreen> createState() => _FamilyJarScreenState();
}

class _FamilyJarScreenState extends State<FamilyJarScreen> {
  Map<String, dynamic>? _family;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final familyId = int.tryParse(widget.id);
      if (familyId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final detail = await BackendApi.instance.getFamilyDetail(familyId);
      if (!mounted) return;
      setState(() {
        _family = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: fIvory, body: Center(child: CircularProgressIndicator(color: fBronze)));
    }
    if (_family == null) {
      return Scaffold(backgroundColor: fIvory, body: Center(child: Column(children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: fBronze),
        const SizedBox(height: 20),
        const Text('Family not found', style: TextStyle(color: fWalnut, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _loadFamily, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
      ])));
    }

    final name = _family!['name']?.toString() ?? 'Family';
    final familyId = _family!['id'].toString();
    final members = (_family!['members'] as List?) ?? [];
    final goals = (_family!['goals'] as List?) ?? [];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: fIvory,
        body: SafeArea(
          child: Column(children: [
            _JarAppBar(name: name, familyId: familyId),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(16), border: Border.all(color: fClay)),
              child: const TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: fWhite, borderRadius: BorderRadius.all(Radius.circular(12))),
                labelColor: fWalnut,
                unselectedLabelColor: fStoneLight,
                labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                tabs: [Tab(text: 'Home'), Tab(text: 'Activity'), Tab(text: 'Together')],
              ),
            ),
            Expanded(child: TabBarView(children: [
              _JarHome(family: _family!, goals: goals, members: members),
              _Activity(family: _family!),
              _Together(family: _family!, members: members),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _JarAppBar extends StatelessWidget {
  const _JarAppBar({required this.name, required this.familyId});
  final String name;
  final String familyId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(children: [
      IconButton(onPressed: () => context.pop(), tooltip: 'Back', icon: const Icon(Icons.arrow_back_ios_new_rounded, color: fWalnut, size: 19)),
      Expanded(child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut))),
      PopupMenuButton<String>(
        tooltip: 'Family options',
        icon: const Icon(Icons.more_horiz_rounded, color: fWalnut),
        onSelected: (value) {
          if (value == 'settings') context.push('/family/settings/$familyId');
          if (value == 'invite') context.push('/family/invitations/$familyId');
        },
        itemBuilder: (_) => const [PopupMenuItem(value: 'invite', child: Text('Invite family')), PopupMenuItem(value: 'settings', child: Text('Jar settings'))],
      ),
    ]),
  );
}

class _JarHome extends StatelessWidget {
  const _JarHome({required this.family, required this.goals, required this.members});
  final Map<String, dynamic> family;
  final List goals;
  final List members;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: [
      _GoalHero(goals: goals),
      const SizedBox(height: 18),
      MizanButton(label: 'Add to our jar', onTap: () => _openContributionSheet(context, familyId: familyId)),
      const SizedBox(height: 10),
      Center(child: Text('Share an act with the family, or let it count privately.', style: const TextStyle(fontSize: 11.5, color: fStoneLight))),
      const SizedBox(height: 30),
      const _SectionTitle(title: 'Today, together'),
      const SizedBox(height: 12),
      _TodayCard(members: members),
      const SizedBox(height: 28),
      const _SectionTitle(title: 'Next milestone'),
      const SizedBox(height: 12),
      if (goals.isNotEmpty) _MilestoneCard(goal: goals.first, jarId: family['id'].toString()),
      const SizedBox(height: 28),
      const _SectionTitle(title: 'A little care'),
      const SizedBox(height: 12),
      _PrayerPreview(familyId: family['id'].toString()),
    ],
  );
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.goals});
  final List goals;

  @override
  Widget build(BuildContext context) {
    final progress = goals.isEmpty ? 0.0 : (goals.first['progress'] as num?)?.toDouble() ?? 0.0;
    final percentage = (progress * 100).round();
    final actsTarget = goals.isEmpty ? 0 : (goals.first['acts_target'] as num?)?.toInt() ?? 0;
    final actsDone = goals.isEmpty ? 0 : (goals.first['acts_done'] as num?)?.toInt() ?? 0;
    final remaining = (actsTarget - actsDone).clamp(0, actsTarget);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
      decoration: BoxDecoration(color: fWalnut, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x1A2F241E), blurRadius: 22, offset: Offset(0, 10))]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('OUR INTENTION', style: TextStyle(color: Color(0xFFE7C99E), fontSize: 10.5, letterSpacing: 1.45, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('$percentage% of our intention', style: const TextStyle(fontFamily: 'Georgia', color: fWhite, fontSize: 25, height: 1.15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text('$remaining more gentle acts to reach this month\'s goal.', style: const TextStyle(color: Color(0xFFE1D4C7), fontSize: 12.5, height: 1.35)),
          const SizedBox(height: 18),
          ProgressTrack(value: progress, height: 8, color: const Color(0xFFE5B877)),
          const SizedBox(height: 8),
          Text('Growing together', style: const TextStyle(color: Color(0xFFD5C5B6), fontSize: 12)),
        ])),
        const SizedBox(width: 4),
        ExcludeSemantics(child: SizedBox(width: 105, height: 145, child: FamilyJarView(fill: progress, size: 102, glow: .7))),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.members});
  final List members;

  @override
  Widget build(BuildContext context) {
    final contributed = members.where((m) => (m['contributed_today'] as bool?) ?? false).toList();
    final names = contributed.take(4).toList();
    final double avatarWidth = names.isEmpty ? 0.0 : 42 + (names.length - 1) * 28;
    return SoftCard(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (names.isNotEmpty) SizedBox(height: 42, width: avatarWidth, child: Stack(children: [for (var i = 0; i < names.length; i++) Positioned(left: i * 28.toDouble(), child: MizanAvatar(name: names[i]['username']?.toString() ?? '?', accent: fBronze, size: 42, contributed: true))])),
          const SizedBox(width: 12),
          Expanded(child: Text('${names.length} family members have added goodness today.', style: const TextStyle(fontSize: 13, height: 1.35, color: fWalnut, fontWeight: FontWeight.w700))),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: fClayLight)),
        Row(children: [const Icon(Icons.auto_awesome_outlined, size: 17, color: fBronze), const SizedBox(width: 9), Expanded(child: Text('Family activities will appear here.', style: const TextStyle(color: fStone, fontSize: 12.5))), const Icon(Icons.arrow_forward_rounded, size: 17, color: fBronze)]),
      ]),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.goal, required this.jarId});
  final Map<String, dynamic> goal;
  final String jarId;

  @override
  Widget build(BuildContext context) => SoftCard(
    onTap: () => context.push('/family/goals/$jarId'),
    padding: const EdgeInsets.all(17),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: fBronze.withValues(alpha: .18), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.flag_outlined, color: fBronze)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal['title']?.toString() ?? 'Goal', style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: fWalnut, fontSize: 16)), const SizedBox(height: 4), Text('${goal['acts_done'] ?? 0} of ${goal['acts_target'] ?? 0} acts', style: const TextStyle(fontSize: 12, color: fStone))])),
      const Icon(Icons.arrow_forward_rounded, color: fBronze),
    ]),
  );
}

class _PrayerPreview extends StatelessWidget {
  const _PrayerPreview({required this.familyId});
  final String familyId;

  @override
  Widget build(BuildContext context) => SoftCard(
    color: fClayPale,
    borderColor: fClay,
    onTap: () => context.push('/family/prayers/$familyId'),
    padding: const EdgeInsets.all(17),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: fWhite, shape: BoxShape.circle, border: Border.all(color: fClay)), child: const Icon(Icons.favorite_border_rounded, color: fBronze)),
      const SizedBox(width: 13),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hold someone close in du\'a', style: TextStyle(fontWeight: FontWeight.w800, color: fWalnut)), SizedBox(height: 4), Text('Ask your family to remember someone in prayer.', style: TextStyle(fontSize: 12.5, height: 1.35, color: fStone))])),
      const Icon(Icons.arrow_forward_rounded, color: fBronze),
    ]),
  );
}

class _Activity extends StatelessWidget {
  const _Activity({required this.family});
  final Map<String, dynamic> family;

  @override
  Widget build(BuildContext context) {
    final activities = (family['activities'] as List?) ?? const [];
    if (activities.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          const Text('Family activity', style: TextStyle(fontFamily: 'Georgia', fontSize: 23, color: fWalnut, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Small moments that are growing your shared intention.', style: TextStyle(color: fStone, fontSize: 12.5)),
          const SizedBox(height: 20),
          const Center(child: Text('No activity yet. Start by adding an act to your family jar.', style: TextStyle(color: fStoneLight, fontSize: 13))),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        const Text('Family activity', style: TextStyle(fontFamily: 'Georgia', fontSize: 23, color: fWalnut, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Small moments that are growing your shared intention.', style: TextStyle(color: fStone, fontSize: 12.5)),
        const SizedBox(height: 20),
        SoftCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [for (var i = 0; i < activities.length; i++) _ActivityRow(activity: activities[i], divider: i < activities.length - 1)])),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.divider});
  final Map<String, dynamic> activity;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final eventType = activity['event_type']?.toString() ?? 'activity';
    final createdAt = activity['created_at']?.toString() ?? '';
    final day = createdAt.split('T').first;
    return Column(children: [Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 37, height: 37, decoration: BoxDecoration(color: fBronze.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.auto_awesome_outlined, color: fBronze, size: 19)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eventType, style: const TextStyle(fontSize: 13, color: fWalnut, height: 1.35)), const SizedBox(height: 4), Text(day, style: const TextStyle(fontSize: 11, color: fStoneLight))]))])), if (divider) const Divider(height: 1, indent: 63, color: fClayLight)]);
  }
}

class _Together extends StatelessWidget {
  const _Together({required this.family, required this.members});
  final Map<String, dynamic> family;
  final List members;

  @override
  Widget build(BuildContext context) {
    final familyId = family['id'].toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Text('Together', style: TextStyle(fontFamily: 'Georgia', fontSize: 23, color: fWalnut, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Care for one another beyond the numbers.', style: TextStyle(color: fStone, fontSize: 12.5)),
        const SizedBox(height: 22),
        _CareLink(icon: Icons.favorite_border_rounded, title: 'Prayer requests', body: 'Ask your family to remember someone in du\'a.', onTap: () => context.push('/family/prayers/$familyId')),
        const SizedBox(height: 12),
        _CareLink(icon: Icons.menu_book_outlined, title: 'Shared reflections', body: 'A quiet place to share what is on your heart.', onTap: () => context.push('/family/reflections/$familyId')),
        const SizedBox(height: 28),
        const _SectionTitle(title: 'Family members'),
        const SizedBox(height: 12),
        if (members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No family members yet. Invite someone to get started.', textAlign: TextAlign.center, style: TextStyle(color: fStone, fontSize: 13)),
          )
        else
          SoftCard(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [for (var i = 0; i < members.take(5).length; i++) _MemberRow(member: members[i], divider: i < members.take(5).length - 1), ListTile(onTap: () => context.push('/family/invitations/$familyId'), title: const Text('Invite someone to the jar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fBronze)), trailing: const Icon(Icons.add_circle_outline_rounded, color: fBronze))])),
      ],
    );
  }
}

class _CareLink extends StatelessWidget {
  const _CareLink({required this.icon, required this.title, required this.body, required this.onTap});
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoftCard(onTap: onTap, padding: const EdgeInsets.all(17), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: fBronze)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: fWalnut)), const SizedBox(height: 4), Text(body, style: const TextStyle(fontSize: 12, color: fStone, height: 1.3))])), const Icon(Icons.arrow_forward_rounded, color: fBronze)]));
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.divider});
  final Map<String, dynamic> member;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final name = member['username']?.toString() ?? 'Unknown';
    final role = member['role']?.toString() ?? 'Member';
    return Column(children: [ListTile(leading: MizanAvatar(name: name, accent: fBronze, size: 40, contributed: member['contributed_today'] as bool? ?? false), title: Text(name, style: const TextStyle(fontSize: 13, color: fWalnut, fontWeight: FontWeight.w700)), subtitle: Text(role, style: const TextStyle(fontSize: 11, color: fStoneLight)), trailing: const Icon(Icons.person_outline_rounded, color: fStonePale)), if (divider) const Divider(height: 1, indent: 68, color: fClayLight)]);
  }
}

class _SectionTitle extends StatelessWidget { const _SectionTitle({required this.title}); final String title; @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 19, color: fWalnut, fontWeight: FontWeight.w700)); }

void _openContributionSheet(BuildContext context, {required String familyId}) {
  final parsedFamilyId = int.tryParse(familyId);
  showModalBottomSheet<void>(context: context, backgroundColor: fIvory, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (sheetContext) => Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99)))), const SizedBox(height: 24), const Text('How would you like to add it?', style: TextStyle(fontFamily: 'Georgia', color: fWalnut, fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 7), const Text('Both choices grow the shared jar.', style: const TextStyle(color: fStone, fontSize: 13)), const SizedBox(height: 20), _ContributionOption(icon: Icons.groups_outlined, title: 'Share with family', body: 'Your family can see this moment in the activity feed.', onTap: () { Navigator.pop(sheetContext); AddActScreen.show(context, familyId: parsedFamilyId); }), const SizedBox(height: 10), _ContributionOption(icon: Icons.visibility_off_outlined, title: 'Keep it private', body: 'It counts toward the jar without showing who or what.', onTap: () { Navigator.pop(sheetContext); AddActScreen.show(context, familyId: parsedFamilyId); })])));
}

class _ContributionOption extends StatelessWidget { const _ContributionOption({required this.icon, required this.title, required this.body, required this.onTap}); final IconData icon; final String title, body; final VoidCallback onTap; @override Widget build(BuildContext context) => SoftCard(onTap: onTap, padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: fBronze)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: fWalnut, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(body, style: const TextStyle(fontSize: 11.5, height: 1.3, color: fStone))])), const Icon(Icons.arrow_forward_rounded, color: fBronze)])); }
