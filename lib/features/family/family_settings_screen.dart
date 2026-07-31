import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/backend_api.dart';
import 'family_models.dart';
import 'family_theme.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  FamilyJar? _jar;
  Map<String, bool> _notifs = {};
  bool _loadingNotifs = true;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() => _loadingNotifs = false);
      return;
    }
    try {
      final settings = await BackendApi.instance.getFamilySettings(familyId);
      final prefs = settings['notification_preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        _notifs = Map<String, bool>.from(prefs.map((k, v) => MapEntry(k, v == true)));
        _loadingNotifs = false;
      });
    } catch (e) {
      setState(() => _loadingNotifs = false);
    }
  }

  Future<void> _handleLeave() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    try {
      await BackendApi.instance.leaveFamilyJar(jarId: familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the family')));
      context.go('/home');
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.brown));
    }
  }

  Future<void> _handleDelete() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    try {
      await BackendApi.instance.deleteFamilyJar(familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family deleted')));
      context.go('/home');
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.brown));
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
        content: Text(body, style: const TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel', style: TextStyle(color: fStone))),
          TextButton(onPressed: () => ctx.pop(true), child: Text(title.split(' ').last, style: const TextStyle(color: fBronze, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ScreenHeader(title: 'Settings', subtitle: jar?.name),
              ),
            ),
            SliverToBoxAdapter(child: _CoverCard(jar: jar)),
            SliverToBoxAdapter(child: _Section(title: 'People', children: [
              _Tile(icon: Icons.groups_outlined, label: 'Members', trailing: '${jar?.memberCount ?? 0}', onTap: () => context.push('/family/members/${widget.id}')),
              _Tile(icon: Icons.badge_outlined, label: 'Roles', trailing: 'Admin · Member', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roles management is coming soon.'), behavior: SnackBarBehavior.floating));
              }),
              _Tile(icon: Icons.shield_outlined, label: 'Permissions', trailing: 'Contribute & view', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions management is coming soon.'), behavior: SnackBarBehavior.floating));
              }),
            ])),
            SliverToBoxAdapter(child: _Section(title: 'Preferences', children: [
              if (_loadingNotifs)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fBronze)),
                )
              else
                ..._notifs.keys.map((k) => _ToggleTile(label: k, value: _notifs[k]!, onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _notifs[k] = v);
                  try {
                    final familyId = int.tryParse(widget.id);
                    if (familyId == null) return;
                    await BackendApi.instance.updateFamilySettings(familyId, notificationPreferences: _notifs);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('Failed to update preferences: $e'), backgroundColor: Colors.brown));
                  }
                })),
              _Tile(icon: Icons.flag_outlined, label: 'Goals', trailing: '${jar?.goals.length ?? 0} active', onTap: () => context.push('/family/goals/${widget.id}')),
            ])),
            SliverToBoxAdapter(child: _DangerZone(
              onArchive: _archiveFamily,
              onLeave: () async {
                final confirmed = await _confirm('Leave Family', 'You will step out of this jar. Your contributions remain as light.');
                if (confirmed == true) await _handleLeave();
              },
              onDelete: () async {
                final confirmed = await _confirm('Delete Family', 'This permanently removes the jar and its memories. This cannot be undone.');
                if (confirmed == true) await _handleDelete();
              },
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  void _archiveFamily() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archive is not available yet. Coming soon.'),
        backgroundColor: fBronze,
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.jar});

  final FamilyJar? jar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(18), border: Border.all(color: fClay)),
              child: Center(child: Icon(jar?.coverIcon ?? Icons.eco_outlined, size: 32, color: fBronze)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FAMILY NAME', style: TextStyle(fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700, color: fStonePale)),
                  const SizedBox(height: 4),
                  Text(jar?.name ?? 'Family Jar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                ],
              ),
            ),
             IconButton(onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover edit is coming soon.'), behavior: SnackBarBehavior.floating));
             }, icon: const Icon(Icons.edit_outlined, size: 18, color: fBronze), visualDensity: VisualDensity.compact),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(title),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.trailing, required this.onTap});

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $trailing',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: fBronze),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: fWalnut))),
                Text(trailing, style: const TextStyle(fontSize: 11, color: fStoneLight)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: fStonePale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: fWalnut))),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: fBronze),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onArchive, required this.onLeave, required this.onDelete});

  final VoidCallback onArchive;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SoftCard(
        color: fClayPale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Manage this jar'),
            const SizedBox(height: 10),
            _Action(label: 'Archive Family', icon: Icons.archive_outlined, onTap: onArchive),
            const SizedBox(height: 8),
            _Action(label: 'Leave Family', icon: Icons.exit_to_app_outlined, onTap: onLeave),
            const SizedBox(height: 8),
            _Action(label: 'Delete Family', icon: Icons.delete_outline, onTap: onDelete, danger: true),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.icon, required this.onTap, this.danger = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFA8554E) : fStone;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: fWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: fClay)),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
