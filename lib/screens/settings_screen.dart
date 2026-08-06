import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/location_service.dart';
import '../../services/prayer_countdown_service.dart';
import '../../services/local_reminder_service.dart';
import '../../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/backend_api.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'notification_preferences_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<UserProfile>? _profileFuture;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendApi.instance.getUserProfile();
    _loadStoredPosition();
  }

  Map<String, double>? _storedPosition;
  TimeOfDay? _fridayReminderTime;

  Future<void> _loadStoredPosition() async {
    final pos = await LocationService.instance.getStoredPosition();
    if (mounted) setState(() => _storedPosition = pos);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reminder_friday_time');
    if (raw != null) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && mounted) setState(() => _fridayReminderTime = TimeOfDay(hour: h, minute: m));
      }
    }
  }

  Future<void> _toggleFridayReminder(UserProfile profile, bool value) async {
    setState(() => _savingReminder = true);
    try {
      if (value) {
        if (!await PushNotificationService.instance.enableForReminders()) {
          throw StateError('Notification permission is required to enable reminders.');
        }
        // Ask the user what time they'd like the Friday reminder.
        final picked = await showTimePicker(context: context, initialTime: _fridayReminderTime ?? const TimeOfDay(hour: 9, minute: 0));
        if (picked == null) {
          // user cancelled - don't toggle
          return;
        }
        await LocalReminderService.instance.enableFridayReminder(true, hour: picked.hour, minute: picked.minute);
        await BackendApi.instance.updatePreferences(fridayReminder: true);
      } else {
        await LocalReminderService.instance.enableFridayReminder(false, hour: 0, minute: 0);
        await BackendApi.instance.updatePreferences(fridayReminder: false);
      }
      if (!mounted) return;
      // refresh profile + local cached time
      setState(() {
        _profileFuture = BackendApi.instance.getUserProfile();
      });
      await _loadStoredPosition();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  Future<void> _toggleGeneralNotifications(UserProfile profile, bool value) async {
    setState(() => _savingReminder = true);
    try {
      if (value && !await PushNotificationService.instance.enableForReminders()) {
        throw StateError('Notification permission is required to enable notifications.');
      }
      await BackendApi.instance.updatePreferences(generalNotifications: value);
      if (!mounted) return;
      setState(() => _profileFuture = BackendApi.instance.getUserProfile());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? kScaffoldDark : kSurface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: dark ? kScaffoldDark : kSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dark ? kInkDark : kInk, size: 19),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 28,
                          color: kInk,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your profile and preferences.',
                        style: TextStyle(color: kMuted, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'Account',
              subtitle: 'Profile and identity',
              child: _SettingsCard(
                icon: Icons.person_outline,
                title: 'Edit profile',
                subtitle: 'Update your name, email, and avatar',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Notifications',
              subtitle: 'Gentle nudges and preferences',
              child: Column(children: [
                _SettingsCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notification preferences',
                  subtitle: 'Manage categories, frequency, and quiet hours',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()));
                  },
                ),
                const SizedBox(height: 10),
                FutureBuilder<UserProfile>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final fridayEnabled = profile?.fridayReminder ?? false;
                    final generalEnabled = profile?.generalNotifications ?? false;
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kLine),
                          ),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                          title: Text('General notifications', style: TextStyle(color: dark ? kInkDark : kInk, fontSize: 15, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              snapshot.connectionState == ConnectionState.waiting
                                  ? 'Loading your preference...'
                                  : 'Receive push notifications for updates and reminders.',
                              style: TextStyle(color: dark ? kMutedDark : kMuted, fontSize: 12.5, height: 1.4),
                            ),
                            value: generalEnabled,
                            onChanged: _savingReminder || profile == null ? null : (value) => _toggleGeneralNotifications(profile, value),
                            activeThumbColor: kBronze,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kLine),
                          ),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                          title: Text('Friday reminder', style: TextStyle(color: dark ? kInkDark : kInk, fontSize: 15, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              snapshot.connectionState == ConnectionState.waiting
                                  ? 'Loading your preference...'
                                  : 'Get a gentle Friday reminder when it is enabled.',
                              style: TextStyle(color: dark ? kMutedDark : kMuted, fontSize: 12.5, height: 1.4),
                            ),
                            value: fridayEnabled,
                            onChanged: _savingReminder || profile == null ? null : (value) => _toggleFridayReminder(profile, value),
                            activeThumbColor: kBronze,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SettingsCard(
                          icon: Icons.place_outlined,
                          title: 'Prayer times & location',
                          subtitle: 'Use device or set manually',
                          onTap: () => _showLocationDialog(),
                        ),
                      ],
                    );
                  },
                ),
              ]),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Goals',
              subtitle: 'View and edit your intentions',
              child: _GoalsSection(),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Privacy',
              subtitle: 'Security and access',
              child: _SettingsCard(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Update your password',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Appearance',
              subtitle: 'How Mizan looks',
              child: _SettingsCard(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: ref.watch(themeModeProvider) == ThemeMode.system
                    ? 'Use your device setting'
                    : (ref.watch(themeModeProvider) == ThemeMode.light ? 'Light' : 'Dark'),
                onTap: () => _showAppearanceSelector(context),
                enabled: true,
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Family',
              subtitle: 'Shared spaces',
              child: _SettingsCard(icon: Icons.groups_outlined, title: 'Family preferences', subtitle: 'Manage invitations and sharing', onTap: null, enabled: false),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Support',
              subtitle: 'Help and product information',
              child: Column(children: [
                _SettingsCard(
                  icon: Icons.help_outline,
                  title: 'Help',
                  subtitle: 'Get support',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
                  },
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Mizan version and legal',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
              ]),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Session',
              subtitle: 'Sign out when you are done',
              child: _SettingsCard(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'End this session on the current device',
                emphasizeDanger: true,
                onTap: () async {
                  await widget.onLogout();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final current = ref.watch(themeModeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationDialog() {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Prayer times & location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_storedPosition == null ? 'No location set' : 'Lat: ${_storedPosition!['lat']}, Lon: ${_storedPosition!['lon']}', style: TextStyle(color: kMuted)),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.my_location_outlined),
                label: const Text('Use device location'),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final snack = ScaffoldMessenger.of(context);
                  try {
                    final pos = await LocationService.instance.getCurrentPosition();
                    if (pos == null) {
                      snack.showSnackBar(const SnackBar(content: Text('Location permission denied or unavailable')));
                      return;
                    }
                    await PrayerCountdownService.instance.refreshTimingsForDate(DateTime.now());
                    await _loadStoredPosition();
                    snack.showSnackBar(const SnackBar(content: Text('Prayer times refreshed using device location')));
                  } catch (e) {
                    snack.showSnackBar(SnackBar(content: Text('Could not get location: $e')));
                  }
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Set manual location'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showManualLocationPrompt();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showManualLocationPrompt() {
    final latController = TextEditingController();
    final lonController = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Set manual location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Latitude')),
            TextField(controller: lonController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Longitude')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim());
              final lon = double.tryParse(lonController.text.trim());
              if (lat == null || lon == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid coordinates')));
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await LocationService.instance.setManualPosition(lat, lon);
                await PrayerCountdownService.instance.refreshTimingsForDate(DateTime.now());
                await _loadStoredPosition();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual location saved and prayer times refreshed')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save manual location: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    });
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: dark ? kBronzeDarkMode : kBronze,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: dark ? kSurfaceDark : kPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dark ? kLineDark : kLine),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasizeDanger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool emphasizeDanger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = emphasizeDanger ? kDanger : (dark ? kBronzeDarkMode : kBronze);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: enabled ? accent.withValues(alpha: (dark ? 0.18 : 0.12)) : (dark ? kElevatedDark : kLine),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: enabled ? accent : kMutedLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: enabled ? (dark ? kInkDark : kInk) : (dark ? kMutedDark : kMutedLight), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: enabled ? (dark ? kMutedDark : kMuted) : (dark ? kMutedDark.withValues(alpha: 0.65) : kMutedLight), fontSize: 12.5)),
                  ],
                ),
              ),
              if (enabled) Icon(Icons.chevron_right_rounded, color: kMutedLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsSection extends StatefulWidget {
  @override
  State<_GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<_GoalsSection> {
  Future<Map<String, dynamic>>? _goalsFuture;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      _goalsFuture = BackendApi.instance.getGoals();
      await _goalsFuture;
    } catch (_) {
      // Goals may not exist yet — that's fine
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: kBronze)),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: kBronze)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load goals. Pull to try again.',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          );
        }

        final data = snapshot.data;
        final goals = data?['goals'] as List<dynamic>? ?? [];

        if (goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No goals yet. Set one from the home screen to get started.',
              style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < goals.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _GoalTile(
                goal: Map<String, dynamic>.from(goals[i] as Map),
                onEdited: _loadGoals,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onEdited});

  final Map<String, dynamic> goal;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final title = goal['title']?.toString() ?? 'Untitled goal';
    final subtitle = goal['subtitle']?.toString();
    final actsTarget = (goal['acts_target'] as num?)?.toInt() ?? 0;
    final actsDone = (goal['acts_done'] as num?)?.toInt() ?? 0;
    final status = goal['status']?.toString() ?? 'active';
    final progress = ((goal['progress'] as num?)?.toDouble() ?? 0.0) * 100;

    final isCompleted = status == 'completed';
    final isArchived = status == 'archived';

    return Material(
      color: kPaper,
      child: InkWell(
        onTap: isArchived ? null : () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => EditGoalScreen(goal: goal),
            ),
          );
          if (result == true) {
            onEdited();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? kSage.withValues(alpha: 0.12)
                      : isArchived
                          ? kLine
                          : kBronze.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline
                      : isArchived
                          ? Icons.archive_outlined
                          : Icons.flag_outlined,
                  color: isCompleted ? kSage : isArchived ? kMutedLight : kBronze,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isArchived ? kMutedLight : kInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle != null && subtitle.isNotEmpty
                          ? '$actsDone / $actsTarget acts · $subtitle'
                          : '$actsDone / $actsTarget acts',
                      style: TextStyle(
                        color: isArchived ? kMutedLight : kMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    if (!isArchived && actsTarget > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          backgroundColor: kLine,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? kSage : kBronze,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isArchived)
                const Icon(Icons.chevron_right_rounded, color: kMutedLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class EditGoalScreen extends StatefulWidget {
  const EditGoalScreen({super.key, required this.goal});

  final Map<String, dynamic> goal;

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal['title']?.toString() ?? '');
    _targetController = TextEditingController(
      text: (widget.goal['acts_target'] as num?)?.toInt().toString() ?? '10',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final target = int.tryParse(_targetController.text.trim()) ?? 10;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal title cannot be empty.')),
      );
      return;
    }

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target must be greater than 0.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final goalId = (widget.goal['id'] as num?)?.toInt() ?? 0;
      await BackendApi.instance.updateGoal(
        goalId: goalId,
        title: title,
        actsTarget: target,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save goal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete goal?', style: TextStyle(fontFamily: 'Georgia', fontSize: 19, fontWeight: FontWeight.w700, color: kInk)),
        content: const Text('This will remove the goal. This action cannot be undone.', style: TextStyle(color: kMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: kDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final goalId = (widget.goal['id'] as num?)?.toInt() ?? 0;
      await BackendApi.instance.deleteGoal(goalId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete goal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit goal', style: TextStyle(color: kInk)),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldCard(
                controller: _titleController,
                label: 'Goal title',
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              _FieldCard(
                controller: _targetController,
                label: 'Target count',
                icon: Icons.track_changes_outlined,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBronze,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: _saving ? null : _save,
                    child: _saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Text('Save changes', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: kDanger),
                child: const Text('Delete goal', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _avatarData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await BackendApi.instance.getAccountSnapshot();
    if (!mounted) return;
    setState(() {
      _nameController.text = profile?.username ?? '';
      _emailController.text = profile?.email ?? '';
      _avatarData = profile?.avatarData;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await BackendApi.instance.updateAccount(
      username: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatarData: _avatarData,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const SnackBar(content: Text('Profile updated.'))));
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 768,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _avatarData = base64Encode(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
        ),
        title: const Text('Settings', style: TextStyle(color: kInk, fontFamily: 'Georgia', fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: kInk),
      ),
        body: const Center(child: CircularProgressIndicator(color: kBronze)),
      );
    }

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit profile', style: TextStyle(color: kInk)),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: kClayLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _avatarData != null && _avatarData!.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.memory(base64Decode(_avatarData!), fit: BoxFit.cover))
                            : const Icon(Icons.person, color: kBronzeDark, size: 40),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18, color: kBronze),
                      label: const Text('Change avatar', style: TextStyle(color: kBronze, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                controller: _nameController,
                label: 'Name',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _FieldCard(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBronze,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: _saving ? null : _save,
                    child: _saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Text('Save changes', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.controller, required this.label, required this.icon});

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kBronze),
          labelText: label,
          labelStyle: const TextStyle(color: kMuted),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
