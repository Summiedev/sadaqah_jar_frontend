import 'package:flutter/material.dart';

import '../../services/backend_api.dart';
import 'family_theme.dart';
import '../../core/theme/theme_extensions.dart';

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
      final members = await BackendApi.instance.getFamilyMembers(
        jarId: familyId,
      );
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = backendErrorMessage(
          e,
          fallback: 'Could not load family members. Please try again.',
        );
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
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.colors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Remove member',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: fWalnut,
              ),
            ),
            content: Text(
              'Remove $name from this family jar? Their past contributions will stay in the family history.',
              style: const TextStyle(color: fStone, fontSize: 13, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: fStone)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: fBronze, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await BackendApi.instance.removeFamilyMember(
        jarId: familyId,
        memberId: memberId,
      );
      if (!mounted) return;
      setState(() {
        _members =
            _members
                .where((m) => (m['id'] as num?)?.toInt() != memberId)
                .toList();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove member: ${backendErrorMessage(e, fallback: 'Please try again.')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ScreenHeader(
                title: 'Members',
                subtitle: '${_members.length} in this family',
              ),
            ),
            if (_saving)
              LinearProgressIndicator(
                minHeight: 2,
                color: colors.primary,
                backgroundColor: Colors.transparent,
              ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: colors.primary, size: 34),
              const SizedBox(height: 12),
              Text(
                'Could not load members',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              MizanOutlineButton(label: 'Try again', onTap: _loadMembers),
            ],
          ),
        ),
      );
    }
    if (_members.isEmpty) {
      return Center(
        child: Text('No members yet.', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: _loadMembers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder:
            (context, index) => _MemberCard(
              member: _members[index],
              onRemove: () => _removeMember(_members[index]),
              onRoleChanged: () => _editRole(_members[index]),
            ),
      ),
    );
  }

  Future<void> _editRole(Map<String, dynamic> member) async {
    final familyId = _familyId;
    final memberId = (member['id'] as num?)?.toInt();
    if (familyId == null ||
        memberId == null ||
        (member['role']?.toString().toLowerCase() == 'owner'))
      return;
    final current =
        member['role']?.toString().toLowerCase() == 'admin'
            ? 'admin'
            : 'member';
    final selected = await showDialog<String>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Change role'),
            children:
                ['admin', 'member']
                    .map(
                      (role) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, role),
                        child: Row(
                          children: [
                            Icon(
                              role == 'admin'
                                  ? Icons.shield_outlined
                                  : Icons.person_outline,
                            ),
                            const SizedBox(width: 12),
                            Text(role[0].toUpperCase() + role.substring(1)),
                            if (role == current) ...[
                              const Spacer(),
                              const Icon(Icons.check),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
    );
    if (selected == null || selected == current || !mounted) return;
    try {
      await BackendApi.instance.updateFamilyMemberRole(
        familyId: familyId,
        memberId: memberId,
        role: selected,
      );
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update role: ${backendErrorMessage(e, fallback: 'Please try again.')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onRemove,
    required this.onRoleChanged,
  });

  final Map<String, dynamic> member;
  final VoidCallback onRemove;
  final VoidCallback onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = member['username']?.toString() ?? 'Family member';
    final role = member['role']?.toString() ?? 'member';
    final joined = member['joined_at']?.toString().split('T').first ?? '';
    final isOwner = role.toLowerCase() == 'owner';

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          MizanAvatar(
            name: name,
            accent: colors.primary,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _RolePill(role),
                    if (joined.isNotEmpty)
                      Text(
                        'Joined $joined',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOwner)
            Icon(Icons.shield_outlined, color: colors.iconSecondary, size: 20)
          else
            PopupMenuButton<String>(
              tooltip: 'Member actions',
              onSelected:
                  (value) => value == 'role' ? onRoleChanged() : onRemove(),
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 'role', child: Text('Change role')),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove member'),
                    ),
                  ],
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: colors.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
