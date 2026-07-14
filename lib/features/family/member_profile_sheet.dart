import 'package:flutter/material.dart';

import 'family_models.dart';
import 'family_theme.dart';

void showMemberProfile(BuildContext context, FamilyMember m) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: fIvory,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scroll) => _MemberSheet(member: m, scroll: scroll),
    ),
  );
}

class _MemberSheet extends StatelessWidget {
  const _MemberSheet({required this.member, required this.scroll});

  final FamilyMember member;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      children: [
        Center(
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99))),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            MizanAvatar(name: member.name, accent: member.accent, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                  const SizedBox(height: 4),
                  Text(member.role, style: const TextStyle(fontSize: 12, color: fBronzeDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: member.contributedToday ? fOliveSoft : fClayPale, borderRadius: BorderRadius.circular(999), border: Border.all(color: member.contributedToday ? fOlive : fClay)),
                    child: Text(
                      member.contributedToday ? 'Contributed today' : member.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: member.contributedToday ? fOlive : fStone),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SoftCard(
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: fBronze),
              const SizedBox(width: 8),
              Text(member.joined, style: const TextStyle(fontSize: 12, color: fStone)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Consistency Milestones'),
        const SizedBox(height: 10),
        if (member.milestones.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No milestones yet — every gentle step counts.', style: TextStyle(fontSize: 12.5, height: 1.5, color: fStoneLight, fontStyle: FontStyle.italic)),
          )
        else
          ...member.milestones.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: fBronze.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.emoji_events_outlined, size: 16, color: fBronze),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m, style: const TextStyle(fontSize: 13, color: fWalnut))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        const SectionLabel('Recent Public Activity'),
        const SizedBox(height: 10),
        ...member.recentActivity.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: fOliveSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome_outlined, size: 16, color: fOlive),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(a, style: const TextStyle(fontSize: 13, color: fWalnut))),
              ],
            ),
          ),
        ),
        if (member.reflections.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('Shared Reflections'),
          const SizedBox(height: 10),
          ...member.reflections.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                color: fClayPale,
                padding: const EdgeInsets.all(14),
                child: Text('“$r”', style: const TextStyle(fontSize: 13.5, height: 1.5, fontStyle: FontStyle.italic, color: fWalnut)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        MizanOutlineButton(label: 'Send a quiet du\'a', onTap: () => Navigator.of(context).pop()),
      ],
    );
  }
}
