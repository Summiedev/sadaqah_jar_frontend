import 'package:flutter/material.dart';

import '../../services/backend_api.dart';
import 'family_theme.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? get _familyId => int.tryParse(widget.id);

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final familyId = _familyId;
    if (familyId == null) {
      setState(() {
        _loading = false;
        _error = 'This family could not be opened.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await BackendApi.instance.getFamilyMembers(jarId: familyId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final familyId = _familyId;
    final memberId = (member['id'] as num?)?.toInt();
    if (familyId == null || memberId == null) return;

    final name = member['username']?.toString() ?? 'this member';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Remove member',
          style: TextStyle(fontFamily: 'Georgia', fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut),
        ),
        content: Text(
          'Remove $name from this family jar? Their past contributions will stay in the family history.',
          style: const TextStyle(color: fStone, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: fStone))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: fBronze, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await BackendApi.instance.removeFamilyMember(jarId: familyId, memberId: memberId);
      if (!mounted) return;
      setState(() {
        _members = _members.where((m) => (m['id'] as num?)?.toInt() != memberId).toList();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name removed'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove member: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ScreenHeader(title: 'Members', subtitle: '${_members.length} in this family'),
            ),
            if (_saving) const LinearProgressIndicator(minHeight: 2, color: fBronze, backgroundColor: Colors.transparent),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: fBronze));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: fBronze, size: 34),
              const SizedBox(height: 12),
              const Text('Could not load members', style: TextStyle(fontFamily: 'Georgia', color: fWalnut, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: fStone, fontSize: 12, height: 1.45)),
              const SizedBox(height: 14),
              MizanOutlineButton(label: 'Try again', onTap: _loadMembers),
            ],
          ),
        ),
      );
    }
    if (_members.isEmpty) {
      return const Center(child: Text('No members yet.', style: TextStyle(color: fStone)));
    }

    return RefreshIndicator(
      color: fBronze,
      onRefresh: _loadMembers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _MemberCard(
          member: _members[index],
          onRemove: () => _removeMember(_members[index]),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onRemove});

  final Map<String, dynamic> member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = member['username']?.toString() ?? 'Family member';
    final role = member['role']?.toString() ?? 'member';
    final joined = member['joined_at']?.toString().split('T').first ?? '';
    final isOwner = role.toLowerCase() == 'owner';

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          MizanAvatar(name: name, accent: isOwner ? fBronzeDark : fBronze, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: fWalnut, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _RolePill(role),
                    if (joined.isNotEmpty) Text('Joined $joined', style: const TextStyle(fontSize: 11, color: fStoneLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOwner)
            const Icon(Icons.shield_outlined, color: fStonePale, size: 20)
          else
            IconButton(
              tooltip: 'Remove member',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined, color: fBronze, size: 20),
            ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill(this.role);

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fClayPale,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: fClay),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(fontSize: 9, color: fBronzeDark, fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
    );
  }
}
