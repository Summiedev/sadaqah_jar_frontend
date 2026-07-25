import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/add_act_screen.dart';
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
  @override
  Widget build(BuildContext context) {
    final jar = getFamilyById(widget.id);
    if (jar == null) {
      return const Scaffold(backgroundColor: fIvory, body: Center(child: Text('Family not found', style: TextStyle(color: fStone))));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: fIvory,
        body: SafeArea(
          child: Column(children: [
            _JarAppBar(jar: jar),
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
            Expanded(child: TabBarView(children: [_JarHome(jar: jar), _Activity(jar: jar), _Together(jar: jar)])),
          ]),
        ),
      ),
    );
  }
}

class _JarAppBar extends StatelessWidget {
  const _JarAppBar({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          IconButton(onPressed: () => context.pop(), tooltip: 'Back', icon: const Icon(Icons.arrow_back_ios_new_rounded, color: fWalnut, size: 19)),
          Expanded(child: Text(jar.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut))),
          PopupMenuButton<String>(
            tooltip: 'Family options',
            icon: const Icon(Icons.more_horiz_rounded, color: fWalnut),
            onSelected: (value) {
              if (value == 'settings') context.push('/family/settings/${jar.id}');
              if (value == 'invite') context.push('/family/invitations/${jar.id}');
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'invite', child: Text('Invite family')), PopupMenuItem(value: 'settings', child: Text('Jar settings'))],
          ),
        ]),
      );
}

class _JarHome extends StatelessWidget {
  const _JarHome({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _GoalHero(jar: jar),
          const SizedBox(height: 18),
          MizanButton(label: 'Add to our jar', onTap: () => _openContributionSheet(context)),
          const SizedBox(height: 10),
          Center(child: Text('Share an act with the family, or let it count privately.', style: const TextStyle(fontSize: 11.5, color: fStoneLight))),
          const SizedBox(height: 30),
          const _SectionTitle(title: 'Today, together'),
          const SizedBox(height: 12),
          _TodayCard(jar: jar),
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Next milestone'),
          const SizedBox(height: 12),
          _MilestoneCard(goal: jar.goals.first, jarId: jar.id),
          const SizedBox(height: 28),
          const _SectionTitle(title: 'A little care'),
          const SizedBox(height: 12),
          _PrayerPreview(jar: jar),
        ],
      );
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) {
    final percentage = (jar.progress * 100).round();
    final remaining = jar.goals.isEmpty ? 0 : jar.goals.first.actsTarget - jar.goals.first.actsDone;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
      decoration: BoxDecoration(color: fWalnut, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x1A2F241E), blurRadius: 22, offset: Offset(0, 10))]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(jar.goalLabel.toUpperCase(), style: const TextStyle(color: Color(0xFFE7C99E), fontSize: 10.5, letterSpacing: 1.45, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('$percentage% of our intention', style: const TextStyle(fontFamily: 'Georgia', color: fWhite, fontSize: 25, height: 1.15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text('$remaining more gentle acts to reach this month’s goal.', style: const TextStyle(color: Color(0xFFE1D4C7), fontSize: 12.5, height: 1.35)),
          const SizedBox(height: 18),
          ProgressTrack(value: jar.progress, height: 8, color: const Color(0xFFE5B877)),
          const SizedBox(height: 8),
          Text('${jar.daysRemaining} days remaining', style: const TextStyle(color: Color(0xFFD5C5B6), fontSize: 12)),
        ])),
        const SizedBox(width: 4),
        ExcludeSemantics(child: SizedBox(width: 105, height: 145, child: FamilyJarView(fill: jar.progress, size: 102, glow: .7))),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) {
    final members = jar.members.where((member) => member.contributedToday).take(4).toList();
    final double avatarWidth = members.isEmpty ? 0.0 : 42 + (members.length - 1) * 28;
    return SoftCard(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (members.isNotEmpty) SizedBox(height: 42, width: avatarWidth, child: Stack(children: [for (var i = 0; i < members.length; i++) Positioned(left: i * 28.toDouble(), child: MizanAvatar(name: members[i].name, accent: members[i].accent, size: 42, contributed: true))])),
          const SizedBox(width: 12),
          Expanded(child: Text('${members.length} family members have added goodness today.', style: const TextStyle(fontSize: 13, height: 1.35, color: fWalnut, fontWeight: FontWeight.w700))),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: fClayLight)),
        Row(children: [const Icon(Icons.auto_awesome_outlined, size: 17, color: fBronze), const SizedBox(width: 9), Expanded(child: Text(jar.lastActivity, style: const TextStyle(color: fStone, fontSize: 12.5))), const Icon(Icons.arrow_forward_rounded, size: 17, color: fBronze)]),
      ]),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.goal, required this.jarId});
  final FamilyGoal goal;
  final String jarId;
  @override
  Widget build(BuildContext context) => SoftCard(
        onTap: () => context.push('/family/goals/$jarId'),
        padding: const EdgeInsets.all(17),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: goal.accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.flag_outlined, color: goal.accent)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.title, style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: fWalnut, fontSize: 16)), const SizedBox(height: 4), Text('${goal.actsDone} of ${goal.actsTarget} acts • ${(goal.progress * 100).round()}% complete', style: const TextStyle(fontSize: 12, color: fStone))])),
          const Icon(Icons.arrow_forward_rounded, color: fBronze),
        ]),
      );
}

class _PrayerPreview extends StatelessWidget {
  const _PrayerPreview({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) => SoftCard(
        color: fClayPale,
        borderColor: fClay,
        onTap: () => context.push('/family/prayers/${jar.id}'),
        padding: const EdgeInsets.all(17),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: fWhite, shape: BoxShape.circle, border: Border.all(color: fClay)), child: const Icon(Icons.favorite_border_rounded, color: fBronze)),
          const SizedBox(width: 13),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hold someone close in du’a', style: TextStyle(fontWeight: FontWeight.w800, color: fWalnut)), SizedBox(height: 4), Text('A family member asked the family to pray.', style: TextStyle(fontSize: 12.5, height: 1.35, color: fStone))])),
          const Icon(Icons.arrow_forward_rounded, color: fBronze),
        ]),
      );
}

class _Activity extends StatelessWidget {
  const _Activity({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) {
    const events = [('Today', Icons.volunteer_activism_outlined, 'A family member added an act of charity.', fBronze), ('Today', Icons.menu_book_outlined, 'A family member shared a reflection.', fOlive), ('Yesterday', Icons.visibility_off_outlined, 'A private act was added to the jar.', fStoneLight), ('Yesterday', Icons.wb_sunny_outlined, 'A family member completed morning adhkar.', fBronze)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        const Text('Family activity', style: TextStyle(fontFamily: 'Georgia', fontSize: 23, color: fWalnut, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Small moments that are growing your shared intention.', style: TextStyle(color: fStone, fontSize: 12.5)),
        const SizedBox(height: 20),
        SoftCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [for (var i = 0; i < events.length; i++) _ActivityRow(day: events[i].$1, icon: events[i].$2, text: events[i].$3, color: events[i].$4, divider: i != events.length - 1)])),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.day, required this.icon, required this.text, required this.color, required this.divider});
  final String day, text;
  final IconData icon;
  final Color color;
  final bool divider;
  @override
  Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 37, height: 37, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 19)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: const TextStyle(fontSize: 13, color: fWalnut, height: 1.35)), const SizedBox(height: 4), Text(day, style: const TextStyle(fontSize: 11, color: fStoneLight))]))])), if (divider) const Divider(height: 1, indent: 63, color: fClayLight)]);
}

class _Together extends StatelessWidget {
  const _Together({required this.jar});
  final FamilyJar jar;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text('Together', style: TextStyle(fontFamily: 'Georgia', fontSize: 23, color: fWalnut, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Care for one another beyond the numbers.', style: TextStyle(color: fStone, fontSize: 12.5)),
          const SizedBox(height: 22),
          _CareLink(icon: Icons.favorite_border_rounded, title: 'Prayer requests', body: 'Ask your family to remember someone in du’a.', onTap: () => context.push('/family/prayers/${jar.id}')),
          const SizedBox(height: 12),
          _CareLink(icon: Icons.menu_book_outlined, title: 'Shared reflections', body: 'A quiet place to share what is on your heart.', onTap: () => context.push('/family/reflections/${jar.id}')),
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Family members'),
          const SizedBox(height: 12),
          SoftCard(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [for (var i = 0; i < jar.members.take(5).length; i++) _MemberRow(member: jar.members[i], divider: i < jar.members.take(5).length - 1), ListTile(onTap: () => context.push('/family/invitations/${jar.id}'), title: const Text('Invite someone to the jar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fBronze)), trailing: const Icon(Icons.add_circle_outline_rounded, color: fBronze))])),
        ],
      );
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
  final FamilyMember member;
  final bool divider;
  @override
  Widget build(BuildContext context) => Column(children: [ListTile(onTap: () => showMemberProfile(context, member), leading: MizanAvatar(name: member.name, accent: member.accent, size: 40, contributed: member.contributedToday), title: Text(member.name, style: const TextStyle(fontSize: 13, color: fWalnut, fontWeight: FontWeight.w700)), subtitle: Text(member.status, style: const TextStyle(fontSize: 11, color: fStoneLight)), trailing: const Icon(Icons.chevron_right_rounded, color: fStonePale)), if (divider) const Divider(height: 1, indent: 68, color: fClayLight)]);
}

class _SectionTitle extends StatelessWidget { const _SectionTitle({required this.title}); final String title; @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 19, color: fWalnut, fontWeight: FontWeight.w700)); }

void _openContributionSheet(BuildContext context) {
  showModalBottomSheet<void>(context: context, backgroundColor: fIvory, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (sheetContext) => Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99)))), const SizedBox(height: 24), const Text('How would you like to add it?', style: TextStyle(fontFamily: 'Georgia', color: fWalnut, fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 7), const Text('Both choices grow the shared jar.', style: TextStyle(color: fStone, fontSize: 13)), const SizedBox(height: 20), _ContributionOption(icon: Icons.groups_outlined, title: 'Share with family', body: 'Your family can see this moment in the activity feed.', onTap: () { Navigator.pop(sheetContext); AddActScreen.show(context); }), const SizedBox(height: 10), _ContributionOption(icon: Icons.visibility_off_outlined, title: 'Keep it private', body: 'It counts toward the jar without showing who or what.', onTap: () { Navigator.pop(sheetContext); AddActScreen.show(context); })])));
}

class _ContributionOption extends StatelessWidget { const _ContributionOption({required this.icon, required this.title, required this.body, required this.onTap}); final IconData icon; final String title, body; final VoidCallback onTap; @override Widget build(BuildContext context) => SoftCard(onTap: onTap, padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: fBronze)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: fWalnut, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(body, style: const TextStyle(fontSize: 11.5, height: 1.3, color: fStone))])), const Icon(Icons.arrow_forward_rounded, color: fBronze)])); }
