import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import '../../widgets/mizan_async_state.dart';
import '../../widgets/mizan_surface.dart';

class AdminBroadcastsScreen extends StatefulWidget {
  const AdminBroadcastsScreen({super.key});

  @override
  State<AdminBroadcastsScreen> createState() => _AdminBroadcastsScreenState();
}

class _AdminBroadcastsScreenState extends State<AdminBroadcastsScreen> {
  late Future<List<AdminBroadcast>> _future = _load();

  Future<List<AdminBroadcast>> _load() => BackendApi.instance.getAdminBroadcasts();

  void _refresh() => setState(() => _future = _load());

  Future<void> _edit([AdminBroadcast? broadcast]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BroadcastEditor(broadcast: broadcast),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _archive(AdminBroadcast broadcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive broadcast?'),
        content: Text('Users will no longer receive "${broadcast.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendApi.instance.deleteAdminBroadcast(broadcast.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast archived.')));
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(backendErrorMessage(error, fallback: 'Could not archive broadcast.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Broadcasts'),
        actions: [
          IconButton(onPressed: _refresh, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: FutureBuilder<List<AdminBroadcast>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MizanLoadingState(label: 'Loading broadcasts...');
          }
          if (snapshot.hasError) {
            return MizanErrorState(
              title: 'Could not load broadcasts',
              message: backendErrorMessage(snapshot.error!, fallback: 'We could not load broadcasts right now.'),
              onRetry: _refresh,
            );
          }
          final items = snapshot.data ?? const <AdminBroadcast>[];
          if (items.isEmpty) {
            return const MizanEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No broadcasts yet',
              message: 'Create a calm, useful announcement for your community.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return MizanSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _edit(item);
                            if (value == 'archive') _archive(item);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'archive', child: Text('Archive')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.body, style: TextStyle(color: colors.textSecondary, height: 1.4)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(item.isActive ? 'Active' : 'Archived', item.isActive ? colors.success : colors.textMuted),
                        _Tag(item.audience, colors.primary),
                        _Tag('${item.views} views', colors.textSecondary),
                        _Tag('${item.clicks} clicks', colors.textSecondary),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New broadcast'),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _BroadcastEditor extends StatefulWidget {
  const _BroadcastEditor({this.broadcast});
  final AdminBroadcast? broadcast;

  @override
  State<_BroadcastEditor> createState() => _BroadcastEditorState();
}

class _BroadcastEditorState extends State<_BroadcastEditor> {
  late final _title = TextEditingController(text: widget.broadcast?.title ?? '');
  late final _body = TextEditingController(text: widget.broadcast?.body ?? '');
  late final _image = TextEditingController(text: widget.broadcast?.imageUrl ?? '');
  late final _ctaLabel = TextEditingController(text: widget.broadcast?.ctaLabel ?? '');
  late final _ctaLink = TextEditingController(text: widget.broadcast?.ctaLink ?? '');
  late String _audience = widget.broadcast?.audience ?? 'all';
  late String _displayMode = widget.broadcast?.displayMode ?? 'until_dismissed';
  late bool _active = widget.broadcast?.isActive ?? true;
  late DateTime? _startsAt = _parseDate(widget.broadcast?.startsAt);
  late DateTime? _endsAt = _parseDate(widget.broadcast?.endsAt);
  bool _saving = false;

  DateTime? _parseDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    return parsed?.toLocal();
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Not set';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool end}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (end ? _endsAt : _startsAt) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (end) {
        _endsAt = picked;
      } else {
        _startsAt = picked;
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [_title, _body, _image, _ctaLabel, _ctaLink]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.broadcast == null) {
        await BackendApi.instance.createAdminBroadcast(
          title: _title.text.trim(),
          body: _body.text.trim(),
          imageUrl: _image.text.trim(),
          ctaLabel: _ctaLabel.text.trim(),
          ctaLink: _ctaLink.text.trim(),
          startsAt: _startsAt?.toUtc().toIso8601String(),
          endsAt: _endsAt?.toUtc().toIso8601String(),
          audience: _audience,
          displayMode: _displayMode,
          isActive: _active,
        );
      } else {
        await BackendApi.instance.updateAdminBroadcast(
          widget.broadcast!.id,
          title: _title.text.trim(),
          body: _body.text.trim(),
          imageUrl: _image.text.trim(),
          ctaLabel: _ctaLabel.text.trim(),
          ctaLink: _ctaLink.text.trim(),
          startsAt: _startsAt?.toUtc().toIso8601String(),
          endsAt: _endsAt?.toUtc().toIso8601String(),
          clearEndsAt: _endsAt == null && widget.broadcast?.endsAt != null,
          audience: _audience,
          displayMode: _displayMode,
          isActive: _active,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(backendErrorMessage(error, fallback: 'Could not save broadcast.'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.broadcast == null ? 'New broadcast' : 'Edit broadcast', style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field(_title, 'Title'),
              const SizedBox(height: 10),
              _field(_body, 'Message', maxLines: 5),
              const SizedBox(height: 10),
              _field(_image, 'Image URL (optional)'),
              const SizedBox(height: 10),
              _field(_ctaLabel, 'Button label (optional)'),
              const SizedBox(height: 10),
              _field(_ctaLink, 'Button link or deep link (optional)'),
              const SizedBox(height: 12),
              _DateSetting(
                label: 'Starts',
                value: _dateLabel(_startsAt),
                onTap: () => _pickDate(end: false),
              ),
              _DateSetting(
                label: 'Ends',
                value: _dateLabel(_endsAt),
                onTap: () => _pickDate(end: true),
                onClear: _endsAt == null ? null : () => setState(() => _endsAt = null),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All users')),
                  DropdownMenuItem(value: 'verified', child: Text('Verified users')),
                  DropdownMenuItem(value: 'admins', child: Text('Admins')),
                ],
                onChanged: (value) => setState(() => _audience = value ?? 'all'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _displayMode,
                decoration: const InputDecoration(labelText: 'Display behaviour'),
                items: const [
                  DropdownMenuItem(value: 'once', child: Text('Show once')),
                  DropdownMenuItem(value: 'once_per_session', child: Text('Once per session')),
                  DropdownMenuItem(value: 'until_dismissed', child: Text('Until dismissed')),
                  DropdownMenuItem(value: 'until_expiry', child: Text('Until expiry')),
                ],
                onChanged: (value) => setState(() => _displayMode = value ?? 'until_dismissed'),
              ),
              SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _active, onChanged: (value) => setState(() => _active = value)),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save broadcast'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) => TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label));
}

class _DateSetting extends StatelessWidget {
  const _DateSetting({required this.label, required this.value, required this.onTap, this.onClear});

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text(value),
      onTap: onTap,
      trailing: onClear == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(onPressed: onClear, tooltip: 'Clear $label date', icon: const Icon(Icons.clear_rounded)),
    );
  }
}
