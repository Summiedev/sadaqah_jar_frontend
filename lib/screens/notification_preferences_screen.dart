import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';
import '../services/backend_api.dart';
import '../services/location_service.dart';
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
  Map<String, dynamic> _reminderPreferences = {};
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
        final reminderPrefs = prefs['reminder_preferences'];
        if (reminderPrefs is Map) {
          _reminderPreferences = Map<String, dynamic>.from(reminderPrefs);
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
          SnackBar(
            content: Text(
              'Could not load preferences: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_requiresPrayerLocation) {
        // Prayer-relative reminders cannot be calculated from a timezone
        // alone. Resolve the location before changing the backend preference,
        // otherwise the toggle would appear enabled while no Salah schedule
        // could ever be created.
        if (await LocationService.instance.getStoredPosition() == null) {
          await LocationService.instance.getCurrentPosition();
        }
        if (await LocationService.instance.getStoredPosition() == null) {
          throw StateError(
            'Location access is needed to schedule Salah and Nawafil reminders at your local prayer times.',
          );
        }
      }
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
        reminderPreferences: _reminderPreferences,
      );
      if (!mounted) return;
      final prayerLocationAvailable =
          await LocationService.instance.getStoredPosition() != null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _allEnabled &&
                    (_categories['prayer_fardh'] ?? true) &&
                    !prayerLocationAvailable
                ? 'Preferences saved. Allow location access so Mizan can schedule Salah at your local prayer times.'
                : 'Notification preferences saved.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save preferences: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _requiresPrayerLocation {
    if (!_allEnabled) return false;
    final salahEnabled = _categories['prayer_fardh'] ?? true;
    final naflEnabled = _categories['prayer_nafl'] ?? true;
    final prayers = _nestedPreference('prayer_reminders');
    const prayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final hasEnabledSalah = prayerNames.any((prayer) {
      final raw = prayers[prayer];
      if (raw is Map) return raw['enabled'] as bool? ?? true;
      return raw is! bool || raw;
    });
    final nawafilEnabled =
        _reminderPreferences['nawafil_after_salah'] as bool? ?? false;
    return (salahEnabled && hasEnabledSalah) || (naflEnabled && nawafilEnabled);
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
      final delivered = await BackendApi.instance.sendTestPush();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test push sent to $delivered device${delivered == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendErrorMessage(
              error,
              fallback: 'The test notification could not be sent.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.colors.textPrimary,
            size: 19,
          ),
        ),
      ),
      body: SafeArea(
        child:
            _loading
                ? Center(
                  child: CircularProgressIndicator(color: colors.primary),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _buildMasterToggle(),
                    const SizedBox(height: 16),
                    _buildFrequencySection(),
                    const SizedBox(height: 16),
                    _buildQuietHoursSection(),
                    const SizedBox(height: 16),
                    _buildSalahSection(),
                    const SizedBox(height: 16),
                    _buildAdditionalWorshipSection(),
                    const SizedBox(height: 16),
                    _buildDailyTimeSection(),
                    const SizedBox(height: 16),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Enable All Notifications',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Master toggle for every reminder category.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        value: _allEnabled,
        onChanged: (v) => setState(() => _allEnabled = v),
        activeThumbColor: colors.primary,
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
    final colors = context.colors;
    return _SectionCard(
      title: 'Quiet Hours',
      subtitle: 'Do Not Disturb window',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable Quiet Hours',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            value: _quietHoursEnabled,
            onChanged: (v) => setState(() => _quietHoursEnabled = v),
            activeThumbColor: colors.primary,
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
    final colors = context.colors;
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
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _categories[key] ?? true,
              onChanged: (v) => setState(() => _categories[key] = v),
              activeThumbColor: colors.primary,
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _nestedPreference(String key) {
    final value = _reminderPreferences[key];
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  void _setSalahPreference(String prayer, String field, Object value) {
    final prayers = _nestedPreference('prayer_reminders');
    final raw = prayers[prayer];
    final settings =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    settings[field] = value;
    prayers[prayer] = settings;
    setState(
      () =>
          _reminderPreferences = {
            ..._reminderPreferences,
            'prayer_reminders': prayers,
          },
    );
  }

  void _setReminderPreference(String key, bool value) {
    setState(() {
      _reminderPreferences = {..._reminderPreferences, key: value};
    });
  }

  Widget _buildAdditionalWorshipSection() {
    final colors = context.colors;
    return _SectionCard(
      title: 'Additional worship reminders',
      subtitle: 'Optional reminders beyond the daily prayers.',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Friday reminder',
              style: TextStyle(color: colors.textPrimary),
            ),
            subtitle: Text(
              'A gentle Jumu’ah prompt, including Al-Kahf.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            value: _reminderPreferences['friday_reminder'] as bool? ?? false,
            onChanged:
                (value) => _setReminderPreference('friday_reminder', value),
            activeThumbColor: colors.primary,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Tahajjud reminder',
              style: TextStyle(color: colors.textPrimary),
            ),
            subtitle: Text(
              'A quiet optional reminder before Fajr.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            value: _reminderPreferences['tahajjud'] as bool? ?? false,
            onChanged: (value) => _setReminderPreference('tahajjud', value),
            activeThumbColor: colors.primary,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Nawafil after Salah',
              style: TextStyle(color: colors.textPrimary),
            ),
            subtitle: Text(
              '15 minutes after Dhuhr, Maghrib and Isha. No reminder after Fajr or Asr.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            value:
                _reminderPreferences['nawafil_after_salah'] as bool? ?? false,
            onChanged:
                (value) => _setReminderPreference('nawafil_after_salah', value),
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSalahSection() {
    final colors = context.colors;
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const labels = {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };
    const offsets = <int, String>{
      -10: '10 min before',
      -5: '5 min before',
      0: 'At Salah',
      5: '5 min after',
    };
    final settings = _nestedPreference('prayer_reminders');
    return _SectionCard(
      title: 'Salah reminders',
      subtitle: 'Use your local prayer times and choose a gentle lead-in.',
      child: Column(
        children: [
          for (final prayer in prayers)
            Builder(
              builder: (context) {
                final raw = settings[prayer];
                final item =
                    raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : <String, dynamic>{};
                final enabled = item['enabled'] as bool? ?? true;
                final offset = (item['offset_minutes'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            labels[prayer]!,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: enabled,
                          activeThumbColor: colors.primary,
                          onChanged:
                              (value) =>
                                  _setSalahPreference(prayer, 'enabled', value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: offsets.containsKey(offset) ? offset : 0,
                        onChanged:
                            enabled
                                ? (value) {
                                  if (value != null) {
                                    _setSalahPreference(
                                      prayer,
                                      'offset_minutes',
                                      value,
                                    );
                                  }
                                }
                                : null,
                        items:
                            offsets.entries
                                .map(
                                  (entry) => DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTimeSection() {
    final dailyTimes = _nestedPreference('daily_times');
    return _SectionCard(
      title: 'Adhkar and Quran timing',
      subtitle: 'By default, these follow the suggested prayer-relative times.',
      child: Column(
        children: [
          _customTimeRow(
            keyName: 'morning_adhkar',
            title: 'Morning Adhkar',
            subtitle: 'Suggested after Fajr',
            value: dailyTimes['morning_adhkar']?.toString(),
          ),
          _customTimeRow(
            keyName: 'quran',
            title: 'Quran',
            subtitle: 'Suggested around Maghrib; only when unread today',
            value: dailyTimes['quran']?.toString(),
          ),
          _customTimeRow(
            keyName: 'evening_adhkar',
            title: 'Evening Adhkar',
            subtitle: 'Suggested after Asr',
            value: dailyTimes['evening_adhkar']?.toString(),
          ),
        ],
      ),
    );
  }

  Widget _customTimeRow({
    required String keyName,
    required String title,
    required String subtitle,
    required String? value,
  }) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(
        value == null ? subtitle : '$subtitle · Custom: $value',
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _saving ? null : () => _chooseDailyTime(keyName, value),
            child: Text(value ?? 'Set time'),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Use suggested time',
              onPressed: _saving ? null : () => _setDailyTime(keyName, null),
              icon: Icon(
                Icons.restart_alt_rounded,
                color: colors.iconSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseDailyTime(String key, String? current) async {
    final initial = _parseTime(current) ?? const TimeOfDay(hour: 14, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    _setDailyTime(
      key,
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _setDailyTime(String key, String? value) {
    final times = _nestedPreference('daily_times');
    if (value == null) {
      times.remove(key);
    } else {
      times[key] = value;
    }
    setState(
      () =>
          _reminderPreferences = {
            ..._reminderPreferences,
            'daily_times': times,
          },
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
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12.5,
            ),
          ),
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
    final colors = context.colors;
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
