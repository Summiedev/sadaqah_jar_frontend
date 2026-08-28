import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/backend_api.dart';
import '../../core/theme/app_theme.dart';
import 'family_theme.dart';
import '../../core/theme/theme_extensions.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  Map<String, dynamic>? _jar;
  Map<String, bool> _notifs = {};
  bool _loadingNotifs = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() => _loadingNotifs = false);
      return;
    }
    try {
      final detail = await BackendApi.instance.getFamilyDetail(familyId);
      final settings = await BackendApi.instance.getFamilySettings(familyId);
      final prefs =
          settings['notification_preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        _jar = detail;
        _notifs = Map<String, bool>.from(
          prefs.map((k, v) => MapEntry(k, v == true)),
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Left the family')));
      context.go('/home');
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.brown),
      );
    }
  }

  Future<void> _handleDelete() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    try {
      await BackendApi.instance.deleteFamilyJar(familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Family deleted')));
      context.go('/home');
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.brown),
      );
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.colors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: fWalnut,
                fontFamily: 'Georgia',
              ),
            ),
            content: Text(
              body,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: fStone,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Cancel', style: TextStyle(color: fStone)),
              ),
              TextButton(
                onPressed: () => ctx.pop(true),
                child: Text(
                  title.split(' ').last,
                  style: const TextStyle(
                    color: fBronze,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    final memberCount = (jar?['members'] as List?)?.length ?? 0;
    final goalsCount = (jar?['goals'] as List?)?.length ?? 0;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ScreenHeader(
                  title: 'Settings',
                  subtitle: jar?['name']?.toString(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CoverCard(jar: jar, onChooseCoverIcon: _chooseCoverIcon),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'People',
                children: [
                  _Tile(
                    icon: Icons.groups_outlined,
                    label: 'Members',
                    trailing: '$memberCount',
                    onTap: () => context.push('/family/members/${widget.id}'),
                  ),
                  _Tile(
                    icon: Icons.badge_outlined,
                    label: 'Roles',
                    trailing: 'Admin, Member',
                    onTap: () {
                      context.push('/family/members/${widget.id}');
                    },
                  ),
                  _Tile(
                    icon: Icons.shield_outlined,
                    label: 'Permissions',
                    trailing: 'Contribute & view',
                    onTap: () {
                      _showPermissions();
                    },
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Preferences',
                children: [
                  if (_loadingNotifs)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fBronze,
                        ),
                      ),
                    )
                  else
                    ..._notifs.keys.map(
                      (k) => _ToggleTile(
                        label: k,
                        value: _notifs[k]!,
                        onChanged: (v) async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _notifs[k] = v);
                          try {
                            final familyId = int.tryParse(widget.id);
                            if (familyId == null) return;
                            await BackendApi.instance.updateFamilySettings(
                              familyId,
                              notificationPreferences: _notifs,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update preferences: $e',
                                ),
                                backgroundColor: Colors.brown,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  _Tile(
                    icon: Icons.flag_outlined,
                    label: 'Goals',
                    trailing: '$goalsCount active',
                    onTap: () => context.push('/family/goals/${widget.id}'),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _DangerZone(
                onArchive: _archiveFamily,
                onLeave: () async {
                  final confirmed = await _confirm(
                    'Leave Family',
                    'You will step out of this jar. Your contributions remain as light.',
                  );
                  if (confirmed == true) await _handleLeave();
                },
                onDelete: () async {
                  final confirmed = await _confirm(
                    'Delete Family',
                    'This permanently removes the jar and its memories. This cannot be undone.',
                  );
                  if (confirmed == true) await _handleDelete();
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveFamily() async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    final confirmed = await _confirm(
      'Archive Family',
      'Hide this family from your active list? You can restore it later from your archived families.',
    );
    if (confirmed != true || !mounted) return;
    try {
      await BackendApi.instance.archiveFamilyJar(familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family archived'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not archive family: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPermissions() async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.colors.surfaceElevated,
            title: Text(
              'Family permissions',
              style: TextStyle(
                color: ctx.colors.textPrimary,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Owners can manage roles, members, settings and the family. Admins can manage members, goals, prayers and reflections. Members can contribute, view the family and participate in shared activities.',
              style: TextStyle(color: ctx.colors.textSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Done',
                  style: TextStyle(color: ctx.colors.primary),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _chooseCoverIcon(BuildContext context) async {
    final familyId = int.tryParse(widget.id);
    if (familyId == null) return;
    const options = <String, IconData>{
      'heart': Icons.favorite_border_rounded,
      'home': Icons.home_work_outlined,
      'mosque': Icons.mosque_outlined,
      'people': Icons.groups_outlined,
      'leaf': Icons.eco_outlined,
      'star': Icons.star_border_rounded,
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surfaceElevated,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    options.entries
                        .map(
                          (entry) => IconButton(
                            tooltip: entry.key,
                            onPressed: () => Navigator.pop(ctx, entry.key),
                            icon: Icon(
                              entry.value,
                              color: ctx.colors.primary,
                              size: 28,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
    );
    if (selected == null || !mounted || !context.mounted) return;
    try {
      await BackendApi.instance.updateFamily(
        familyId: familyId,
        coverIcon: selected,
      );
      await _loadSettings();
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family cover updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update family cover: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.jar, required this.onChooseCoverIcon});

  final Map<String, dynamic>? jar;
  final Future<void> Function(BuildContext context) onChooseCoverIcon;

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
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.colors.border),
              ),
              child: Center(
                child: Icon(
                  _coverIcon(jar?['cover_icon']?.toString()),
                  size: 32,
                  color: context.colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAMILY NAME',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jar?['name']?.toString() ?? 'Family Jar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onChooseCoverIcon(context),
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: context.colors.primary,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _coverIcon(String? value) => switch (value) {
  'heart' => Icons.favorite_border_rounded,
  'home' => Icons.home_work_outlined,
  'mosque' => Icons.mosque_outlined,
  'people' => Icons.groups_outlined,
  'star' => Icons.star_border_rounded,
  _ => Icons.eco_outlined,
};

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
  const _Tile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                  ),
                ),
                Text(
                  trailing,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: colors.iconSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({
    required this.onArchive,
    required this.onLeave,
    required this.onDelete,
  });

  final VoidCallback onArchive;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SoftCard(
        color: colors.errorContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Manage this jar'),
            const SizedBox(height: 10),
            _Action(
              label: 'Archive Family',
              icon: Icons.archive_outlined,
              onTap: onArchive,
            ),
            const SizedBox(height: 8),
            _Action(
              label: 'Leave Family',
              icon: Icons.exit_to_app_outlined,
              onTap: onLeave,
            ),
            const SizedBox(height: 8),
            _Action(
              label: 'Delete Family',
              icon: Icons.delete_outline,
              onTap: onDelete,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = danger ? colors.error : colors.textSecondary;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
