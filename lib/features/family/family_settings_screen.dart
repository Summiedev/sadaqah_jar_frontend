import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'family_models.dart';
import 'family_theme.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 500));
  FamilyJar? _jar;

  final Map<String, bool> _notifs = {
    'New contributions': true,
    'Reflections shared': true,
    'Prayer requests': true,
    'Member joined': false,
  };

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
            final loading = snap.connectionState != ConnectionState.done;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ScreenHeader(title: 'Settings', subtitle: jar?.name),
                  ),
                ),
                if (loading)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(height: 200, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20)))))))
                else ...[
                  SliverToBoxAdapter(child: _CoverCard(jar: jar)),
                  SliverToBoxAdapter(child: _Section(title: 'People', children: [
                    _Tile(icon: Icons.groups_outlined, label: 'Members', trailing: '${jar?.memberCount ?? 0}', onTap: () {}),
                    _Tile(icon: Icons.badge_outlined, label: 'Roles', trailing: 'Admin · Member', onTap: () {}),
                    _Tile(icon: Icons.shield_outlined, label: 'Permissions', trailing: 'Contribute & view', onTap: () {}),
                  ])),
                  SliverToBoxAdapter(child: _Section(title: 'Preferences', children: [
                    ..._notifs.keys.map((k) => _ToggleTile(label: k, value: _notifs[k]!, onChanged: (v) => setState(() => _notifs[k] = v))),
                    _Tile(icon: Icons.flag_outlined, label: 'Goals', trailing: '${jar?.goals.length ?? 0} active', onTap: () => context.push('/family/goals/${widget.id}')),
                  ])),
                  SliverToBoxAdapter(child: _DangerZone(onArchive: () => _confirm(context, 'Archive Family', 'This jar will be hidden but kept. You can restore it later.'), onLeave: () => _confirm(context, 'Leave Family', 'You will step out of this jar. Your contributions remain as light.'), onDelete: () => _confirm(context, 'Delete Family', 'This permanently removes the jar and its memories. This cannot be undone.'))),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ],
            );
          },
        ),
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
              child: Center(child: Text(jar?.coverEmoji ?? '🌿', style: const TextStyle(fontSize: 32))),
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
            IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18, color: fBronze), visualDensity: VisualDensity.compact),
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
    return Material(
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
    return Material(
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
    );
  }
}

void _confirm(BuildContext context, String title, String body) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: fIvory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
      content: Text(body, style: const TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel', style: TextStyle(color: fStone))),
        TextButton(onPressed: () => context.pop(), child: const Text('Confirm', style: TextStyle(color: fBronze, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}
