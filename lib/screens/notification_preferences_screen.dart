import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_extensions.dart';
import '../services/backend_api.dart';
import '../services/local_reminder_service.dart';
import '../services/push_notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _allEnabled = true;
  String _frequency = 'medium';
  Map<String, bool> _categories = {};
  Map<String, String> _categoryLabels = {};
  bool _quietHoursEnabled = false;
  String _quietStart = '22:00';
  String _quietEnd = '07:00';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await BackendApi.instance.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _allEnabled = prefs['all_enabled'] as bool? ?? true;
        _frequency = prefs['frequency']?.toString() ?? 'medium';
        final cats = prefs['categories'];
        if (cats is Map) {
          _categories = cats.map(
            (k, v) => MapEntry(k.toString(), v as bool? ?? true),
          );
        }
        final labels = prefs['category_labels'];
        if (labels is Map) {
          _categoryLabels = labels.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }
        final qh = prefs['quiet_hours'];
        if (qh is Map) {
          _quietHoursEnabled = qh['enabled'] as bool? ?? false;
          _quietStart = qh['start']?.toString() ?? '22:00';
          _quietEnd = qh['end']?.toString() ?? '07:00';
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load preferences: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_allEnabled &&
          !await PushNotificationService.instance.enableForReminders()) {
        throw StateError(
          'Notification permission is required to enable notifications.',
        );
      }
      await BackendApi.instance.updateNotificationPreferences(
        allEnabled: _allEnabled,
        frequency: _frequency,
        categories: _categories,
        quietHours: {
          'enabled': _quietHoursEnabled,
          'start': _quietStart,
          'end': _quietEnd,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final allowed =
          await PushNotificationService.instance.enableForReminders();
      if (!allowed) {
        throw StateError(
          'Notifications are blocked. Allow notifications for Mizan in device settings.',
        );
      }
      await LocalReminderService.instance.showNow(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: 'Mizan is ready',
        body: 'Your reminders will appear here when they are due.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification sent.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kInk,
            size: 19,
          ),
        ),
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(child: CircularProgressIndicator(color: kBronze))
                : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _buildMasterToggle(),
                    const SizedBox(height: 16),
                    _buildFrequencySection(),
                    const SizedBox(height: 16),
                    _buildQuietHoursSection(),
                    const SizedBox(height: 16),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kBronze,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saving ? null : _save,
                        child:
                            _saving
                                ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                                : Text(
                                  'Save Preferences',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _sendTestNotification,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Send test notification'),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLine),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Enable All Notifications',
          style: TextStyle(
            color: kInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Master toggle for every reminder category.',
          style: TextStyle(color: kMuted, fontSize: 12.5),
        ),
        value: _allEnabled,
        onChanged: (v) => setState(() => _allEnabled = v),
        activeThumbColor: kBronze,
      ),
    );
  }

  Widget _buildFrequencySection() {
    final tokens = context.colors;
    String labelFor(String freq) {
      if (freq == 'low') return 'Low - essential reminders only';
      if (freq == 'medium') return 'Medium - balanced reminders';
      return 'High - frequent reminders';
    }

    return _SectionCard(
      title: 'Frequency',
      subtitle: 'How often you receive reminders',
      child: Column(
        children: [
          for (final freq in ['low', 'medium', 'high'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _frequency = freq),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _frequency == freq
                            ? tokens.primaryContainer
                            : tokens.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          _frequency == freq
                              ? tokens.primary
                              : tokens.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelFor(freq),
                          style: TextStyle(
                            color:
                                _frequency == freq
                                    ? tokens.onPrimaryContainer
                                    : tokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_frequency == freq)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: tokens.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return _SectionCard(
      title: 'Quiet Hours',
      subtitle: 'Do Not Disturb window',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Enable Quiet Hours',
              style: TextStyle(
                color: kInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            value: _quietHoursEnabled,
            onChanged: (v) => setState(() => _quietHoursEnabled = v),
            activeThumbColor: kBronze,
          ),
          if (_quietHoursEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start',
                    value: _quietStart,
                    onChanged: (v) => setState(() => _quietStart = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'End',
                    value: _quietEnd,
                    onChanged: (v) => setState(() => _quietEnd = v),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final orderedKeys = _categoryLabels.keys.toList();
    return _SectionCard(
      title: 'Reminder Categories',
      subtitle: 'Choose what you want to receive',
      child: Column(
        children: [
          for (final key in orderedKeys)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _categoryLabels[key] ?? key,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _categories[key] ?? true,
              onChanged: (v) => setState(() => _categories[key] = v),
              activeThumbColor: kBronze,
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 12.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
