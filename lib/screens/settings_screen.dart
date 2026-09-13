import 'dart:convert';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/location_service.dart';
import '../../services/prayer_countdown_service.dart';
import '../../services/local_reminder_service.dart';
import '../../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/backend_api.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'notification_preferences_screen.dart';
import '../widgets/mizan_async_state.dart';

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
        if (h != null && m != null && mounted) {
          setState(() => _fridayReminderTime = TimeOfDay(hour: h, minute: m));
        }
      }
    }
  }

  Future<void> _toggleFridayReminder(UserProfile profile, bool value) async {
    setState(() => _savingReminder = true);
    try {
      if (value) {
        if (!await PushNotificationService.instance.enableForReminders()) {
          throw StateError(
            'Notification permission is required to enable reminders.',
          );
        }
        if (!mounted) return;
        // Ask the user what time they'd like the Friday reminder.
        final picked = await showTimePicker(
          context: context,
          initialTime:
              _fridayReminderTime ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked == null) {
          // user cancelled - don't toggle
          return;
        }
        await LocalReminderService.instance.enableFridayReminder(
          true,
          hour: picked.hour,
          minute: picked.minute,
        );
        await BackendApi.instance.updatePreferences(fridayReminder: true);
      } else {
        await LocalReminderService.instance.enableFridayReminder(
          false,
          hour: 0,
          minute: 0,
        );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(
                error,
                fallback: 'Unable to update your notification settings.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingReminder = false);
      }
    }
  }

  Future<void> _toggleGeneralNotifications(
    UserProfile profile,
    bool value,
  ) async {
    setState(() => _savingReminder = true);
    try {
      if (value &&
          !await PushNotificationService.instance.enableForReminders()) {
        throw StateError(
          'Notification permission is required to enable notifications.',
        );
      }
      await BackendApi.instance.updatePreferences(generalNotifications: value);
      if (!mounted) return;
      final refreshedProfile = BackendApi.instance.getUserProfile();
      setState(() {
        _profileFuture = refreshedProfile;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(
                error,
                fallback: 'Unable to update your notification settings.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: tokens.iconPrimary,
            size: 19,
          ),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: MizanSpacing.screen,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 28,
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your profile and preferences.',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
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
                onTap: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (mounted) {
                    setState(
                      () =>
                          _profileFuture = BackendApi.instance.getUserProfile(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Notifications',
              subtitle: 'Gentle nudges and preferences',
              child: Column(
                children: [
                  _SettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notification preferences',
                    subtitle: 'Manage categories, frequency, and quiet hours',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationPreferencesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<UserProfile>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final fridayEnabled = profile?.fridayReminder ?? false;
                      final generalEnabled =
                          profile?.generalNotifications ?? false;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tokens.borderSubtle),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'General notifications',
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Loading your preference...'
                                    : 'Receive push notifications for updates and reminders.',
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                              value: generalEnabled,
                              onChanged:
                                  _savingReminder || profile == null
                                      ? null
                                      : (value) => _toggleGeneralNotifications(
                                        profile,
                                        value,
                                      ),
                              activeThumbColor: tokens.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tokens.borderSubtle),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Friday reminder',
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Loading your preference...'
                                    : 'Get a gentle Friday reminder when it is enabled.',
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                              value: fridayEnabled,
                              onChanged:
                                  _savingReminder || profile == null
                                      ? null
                                      : (value) =>
                                          _toggleFridayReminder(profile, value),
                              activeThumbColor: tokens.primary,
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
                ],
              ),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
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
                subtitle:
                    ref.watch(themeModeProvider) == ThemeMode.system
                        ? 'Use your device setting'
                        : (ref.watch(themeModeProvider) == ThemeMode.light
                            ? 'Light'
                            : 'Dark'),
                onTap: () => _showAppearanceSelector(context),
                enabled: true,
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Family',
              subtitle: 'Shared spaces',
              child: _SettingsCard(
                icon: Icons.groups_outlined,
                title: 'Family preferences',
                subtitle: 'Manage invitations and sharing',
                onTap: null,
                enabled: false,
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Support',
              subtitle: 'Help and product information',
              child: Column(
                children: [
                  _SettingsCard(
                    icon: Icons.help_outline,
                    title: 'Help',
                    subtitle: 'Get support',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Mizan version and legal',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
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
      backgroundColor: context.colors.surfaceElevated,
      showDragHandle: true,
      builder: (ctx) {
        final current = ref.watch(themeModeProvider);
        final tokens = ctx.colors;
        Widget option({
          required ThemeMode mode,
          required String label,
          required IconData icon,
        }) {
          final selected = current == mode;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color:
                  selected ? tokens.primaryContainer : tokens.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: selected ? tokens.primary : tokens.iconSecondary,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color:
                                selected
                                    ? tokens.onPrimaryContainer
                                    : tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: tokens.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                option(
                  mode: ThemeMode.system,
                  label: 'System',
                  icon: Icons.settings_suggest_outlined,
                ),
                option(
                  mode: ThemeMode.light,
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                ),
                option(
                  mode: ThemeMode.dark,
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final tokens = ctx.colors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Prayer times & location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _storedPosition == null
                      ? 'No location set'
                      : 'Lat: ${_storedPosition!['lat']}, Lon: ${_storedPosition!['lon']}',
                  style: TextStyle(color: tokens.textSecondary),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Use device location'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final snack = ScaffoldMessenger.of(context);
                    try {
                      final pos =
                          await LocationService.instance.getCurrentPosition();
                      if (pos == null) {
                        snack.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location permission denied or unavailable',
                            ),
                          ),
                        );
                        return;
                      }
                      await PrayerCountdownService.instance
                          .refreshTimingsForDate(DateTime.now());
                      await _loadStoredPosition();
                      snack.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Prayer times refreshed using device location',
                          ),
                        ),
                      );
                    } catch (e) {
                      snack.showSnackBar(
                        SnackBar(content: Text('Could not get location: $e')),
                      );
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
      },
    );
  }

  void _showManualLocationPrompt() {
    final latController = TextEditingController();
    final lonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set manual location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lonController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lon = double.tryParse(lonController.text.trim());
                if (lat == null || lon == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid coordinates'),
                      ),
                    );
                  }
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await LocationService.instance.setManualPosition(lat, lon);
                  await PrayerCountdownService.instance.refreshTimingsForDate(
                    DateTime.now(),
                  );
                  await _loadStoredPosition();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Manual location saved and prayer times refreshed',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not save manual location: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfaceContainer,
              borderRadius: BorderRadius.circular(MizanRadii.card),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: ClipRRect(
             borderRadius: BorderRadius.circular(MizanRadii.card),
            child: child,
          ),
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
    final tokens = context.colors;
    final accent = emphasizeDanger ? tokens.error : tokens.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
         borderRadius: BorderRadius.circular(MizanRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      enabled
                          ? accent.withValues(alpha: 0.14)
                          : tokens.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? accent : tokens.iconDisabled,
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
                        color:
                            enabled ? tokens.textPrimary : tokens.textDisabled,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            enabled ? tokens.textSecondary : tokens.textMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.iconSecondary,
                  size: 18,
                ),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _goalsFuture = BackendApi.instance.getGoals();
      await _goalsFuture;
      _error = null;
    } catch (error) {
      _error = backendErrorMessage(
        error,
        fallback: 'We could not load your goal history.',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: MizanSpacing.card,
        child: const SizedBox(
          height: 120,
          child: MizanLoadingState(label: 'Loading your goals...'),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _goalsFuture == null) {
          return const SizedBox(
            height: 120,
            child: MizanLoadingState(label: 'Loading your goals...'),
          );
        }

        if (snapshot.hasError || _error != null) {
          return SizedBox(
            height: 220,
            child: MizanErrorState(
              message: _error ?? 'We could not load your goal history.',
              onRetry: _loadGoals,
            ),
          );
        }

        final data = snapshot.data;
        final goals = data?['goals'] as List<dynamic>? ?? [];

        if (goals.isEmpty) {
          return const SizedBox(
            height: 220,
            child: MizanEmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              message: 'Set one from the home screen to begin your intention.',
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
    final isHistory = status != 'active';
    final tokens = context.colors;

    return Material(
      color: tokens.surfaceElevated,
      child: InkWell(
        onTap:
            status != 'active'
                ? null
                : () async {
                  final result = await Navigator.of(context).push<dynamic>(
                    MaterialPageRoute(
                      builder: (_) => EditGoalScreen(goal: goal),
                    ),
                  );
                  if (result != null) {
                    onEdited();
                  }
                },
        borderRadius: BorderRadius.circular(MizanRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? tokens.success.withValues(alpha: 0.14)
                            : isHistory
                          ? tokens.surfaceContainerHigh
                          : tokens.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline
                      : isHistory
                      ? Icons.archive_outlined
                      : Icons.flag_outlined,
                  color:
                      isCompleted
                          ? tokens.success
                          : isHistory
                          ? tokens.iconDisabled
                          : tokens.primary,
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
                        color:
                            isHistory
                                ? tokens.textDisabled
                                : tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle != null && subtitle.isNotEmpty
                          ? '$actsDone / $actsTarget acts · $subtitle'
                          : '$actsDone / $actsTarget acts',
                      style: TextStyle(
                        color:
                            isHistory
                                ? tokens.textDisabled
                                : tokens.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    if (actsTarget > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          backgroundColor: tokens.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? tokens.success : tokens.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status == 'active')
                Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.iconSecondary,
                  size: 18,
                ),
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
  late final String _initialTitle;
  late final String _initialTarget;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.goal['title']?.toString() ?? '',
    );
    _targetController = TextEditingController(
      text: (widget.goal['acts_target'] as num?)?.toInt().toString() ?? '10',
    );
    _initialTitle = _titleController.text;
    _initialTarget = _targetController.text;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _titleController.text != _initialTitle ||
      _targetController.text != _initialTarget;

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your goal changes have not been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving) return;
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
      final goalId = (widget.goal['id'] as num?)?.toInt();
      if (goalId == null || goalId <= 0) {
        throw BackendApiException('Goal is no longer available.', 404);
      }
      final updated = await BackendApi.instance.updateGoal(
        goalId: goalId,
        title: title,
        actsTarget: target,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save goal: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _complete() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Complete this goal?'),
            content: const Text(
              'Your progress will stay in goal history, and you can set another goal afterwards.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Complete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final goalId = (widget.goal['id'] as num?)?.toInt();
      if (goalId == null || goalId <= 0) {
        throw BackendApiException('Goal is no longer available.', 404);
      }
      await BackendApi.instance.updateGoalStatus(goalId, 'completed');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Could not complete goal: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _replace() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final target = int.tryParse(_targetController.text.trim()) ?? 0;
    if (title.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and a target greater than 0.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Replace this goal?'),
            content: const Text(
              'The current goal will stay in your history and this will become your new active goal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep goal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Replace'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final goalId = (widget.goal['id'] as num?)?.toInt();
      if (goalId == null || goalId <= 0) {
        throw BackendApiException('Goal is no longer available.', 404);
      }
      final now = DateTime.now();
      final month =
          widget.goal['month']?.toString() ??
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final replacement = await BackendApi.instance.replaceGoal(
        goalId: goalId,
        title: title,
        actsTarget: target,
        month: month,
      );
      if (!mounted) return;
      Navigator.of(context).pop(replacement);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not replace goal: ${backendErrorMessage(e, fallback: 'Please try again.')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Edit goal'),
          leading: IconButton(
            onPressed: _handleBack,
            icon: Icon(Icons.arrow_back_rounded, color: tokens.iconPrimary),
            tooltip: 'Back',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: MizanSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldCard(
                  controller: _titleController,
                  label: 'Goal title',
                  icon: Icons.flag_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _FieldCard(
                  controller: _targetController,
                  label: 'Target count',
                  icon: Icons.track_changes_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MizanRadii.control),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child:
                        _saving
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tokens.onPrimary,
                              ),
                            )
                            : Text(
                              'Save changes',
                              style: TextStyle(
                                fontSize: 16,
                                color: tokens.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
                if (widget.goal['status']?.toString() == 'active') ...[
                  const SizedBox(height: MizanSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _complete,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Complete current goal'),
                  ),
                  const SizedBox(height: MizanSpacing.sm),
                  TextButton(
                    onPressed: _saving ? null : _replace,
                    child: const Text('Replace current goal'),
                  ),
                ],
              ],
            ),
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

enum _EmailChangeState {
  idle,
  reauthRequired,
  sending,
  sent,
  verifying,
  verified,
  cancelled,
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _savingProfile = false;
  String? _avatarData;
  String? _errorMessage;
  String? _successMessage;
  String _originalName = '';
  String? _originalAvatarData;

  _EmailChangeState _emailState = _EmailChangeState.idle;
  String? _pendingNewEmail;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _emailController.addListener(_onEmailChanged);
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    _otpController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);
    _otpController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  void _onEmailChanged() {
    if (_emailState == _EmailChangeState.sent ||
        _emailState == _EmailChangeState.verifying) {
      return;
    }
    final currentEmail = _emailController.text.trim();
    if (_originalEmail != null &&
        currentEmail != _originalEmail &&
        _emailState == _EmailChangeState.idle) {
      setState(() {
        _emailState = _EmailChangeState.reauthRequired;
        _errorMessage = null;
      });
    } else if (_originalEmail != null &&
        currentEmail == _originalEmail &&
        _emailState == _EmailChangeState.reauthRequired) {
      setState(() {
        _emailState = _EmailChangeState.idle;
        _errorMessage = null;
      });
    }
  }

  Future<void> _load() async {
    try {
      final profile = await BackendApi.instance.getUserProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = profile.username;
        _emailController.text = profile.email;
        _avatarData = profile.avatarData;
        _loading = false;
        _originalEmail = profile.email;
        _originalName = profile.username;
        _originalAvatarData = profile.avatarData;
      });
    } catch (_) {
      try {
        final profile = await BackendApi.instance.getAccountSnapshot();
        if (!mounted) return;
        setState(() {
          _nameController.text = profile?.username ?? '';
          _emailController.text = profile?.email ?? '';
          _avatarData = profile?.avatarData;
          _loading = false;
          _originalEmail = profile?.email;
          _originalName = profile?.username ?? '';
          _originalAvatarData = profile?.avatarData;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    }
  }

  bool get _emailChanged {
    // Compare against the initially loaded value by checking if we have a pending
    // email or the current text differs from what's in the name field (loaded first).
    // Simpler: track original email.
    return _originalEmail != null &&
        _emailController.text.trim() != _originalEmail;
  }

  String? _originalEmail;

  bool get _hasUnsavedChanges =>
      !_loading &&
      (_nameController.text.trim() != _originalName.trim() ||
          _emailController.text.trim() != (_originalEmail ?? '').trim() ||
          _avatarData != _originalAvatarData ||
          _passwordController.text.isNotEmpty ||
          _otpController.text.isNotEmpty ||
          _emailState != _EmailChangeState.idle);

  Future<void> _handleBack() async {
    if (_savingProfile || _emailState == _EmailChangeState.verifying) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your profile changes have not been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _saveProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _savingProfile = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await BackendApi.instance.updateAccount(
        username: name,
        avatarData: _avatarData,
      );
      if (!mounted) return;
      setState(() => _successMessage = 'Profile updated.');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _errorMessage =
            'Could not save changes. Please check your connection and try again.';
      });
    }
  }

  Future<void> _startEmailChange() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!newEmail.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(
        () =>
            _errorMessage =
                'Please enter your current password to confirm this change.',
      );
      return;
    }

    setState(() {
      _emailState = _EmailChangeState.sending;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await BackendApi.instance.updateAccount(
        username: _nameController.text.trim(),
        avatarData: _avatarData,
      );
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.reauthRequired;
        _errorMessage = 'Could not save profile: ${e.message}';
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.reauthRequired;
        _errorMessage = 'Network error saving profile. Please try again.';
      });
      return;
    }

    try {
      await BackendApi.instance.requestEmailChange(
        currentPassword: password,
        newEmail: newEmail,
      );
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.sent;
        _pendingNewEmail = newEmail;
        _resendCooldown = 60;
        _passwordController.clear();
      });
      _startResendCooldown();
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.reauthRequired;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.reauthRequired;
        _errorMessage =
            'Network error. Please check your connection and try again.';
      });
    }
  }

  Future<void> _confirmEmailChange() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _otpController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _emailState = _EmailChangeState.verifying;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.confirmEmailChange(token: code);
      if (!mounted) return;
      final profile = await BackendApi.instance.getUserProfile();
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.verified;
        _successMessage = 'Email updated successfully.';
        _emailController.text = profile.email;
        _nameController.text = profile.username;
        _otpController.clear();
        _pendingNewEmail = null;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.sent;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _emailState = _EmailChangeState.sent;
        _errorMessage =
            'Network error. Please check your connection and try again.';
      });
    }
  }

  Future<void> _cancelEmailChange() async {
    try {
      await BackendApi.instance.cancelEmailChange();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _emailState = _EmailChangeState.idle;
      _pendingNewEmail = null;
      _otpController.clear();
      _passwordController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;
    try {
      await BackendApi.instance.resendEmailChangeVerification();
      if (!mounted) return;
      setState(() {
        _resendCooldown = 60;
      });
      _startResendCooldown();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Could not resend code. Please try again.',
      );
    }
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown -= 1;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    if (_loading) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: tokens.background,
          appBar: AppBar(
            backgroundColor: tokens.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded, color: tokens.iconPrimary),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Center(child: CircularProgressIndicator(color: tokens.primary)),
        ),
      );
    }

    final isEmailChanging =
        _emailState == _EmailChangeState.reauthRequired ||
        _emailState == _EmailChangeState.sending ||
        _emailState == _EmailChangeState.sent ||
        _emailState == _EmailChangeState.verifying ||
        _emailState == _EmailChangeState.verified;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          surfaceTintColor: Colors.transparent,
          title: Text(isEmailChanging ? 'Change email' : 'Edit profile'),
          leading: IconButton(
            onPressed: _handleBack,
            icon: Icon(Icons.arrow_back_rounded, color: tokens.iconPrimary),
            tooltip: 'Back',
          ),
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
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: tokens.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child:
                              _avatarData != null && _avatarData!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.memory(
                                      base64Decode(_avatarData!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Icon(
                                    Icons.person,
                                    color: tokens.primary,
                                    size: 40,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: tokens.primary,
                        ),
                        label: Text(
                          'Change avatar',
                          style: TextStyle(
                            color: tokens.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FieldCard(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.badge_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _EmailFieldCard(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email,
                  emailState: _emailState,
                ),
                if (_emailState == _EmailChangeState.reauthRequired) ...[
                  const SizedBox(height: 12),
                  _FieldCard(
                    controller: _passwordController,
                    label: 'Current password',
                    icon: Icons.lock_outline,
                    obscure: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _savingProfile ? null : _startEmailChange,
                    child:
                        _savingProfile
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tokens.onPrimary,
                              ),
                            )
                            : const Text('Send verification code'),
                  ),
                ],
                if (_emailState == _EmailChangeState.sent ||
                    _emailState == _EmailChangeState.verifying) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Enter the 6-digit code sent to $_pendingNewEmail',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    _emailState == _EmailChangeState.verifying
                                        ? null
                                        : _confirmEmailChange,
                                child:
                                    _emailState == _EmailChangeState.verifying
                                        ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                          ),
                                        )
                                        : const Text('Verify email'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed:
                                  _emailState == _EmailChangeState.verifying
                                      ? null
                                      : _cancelEmailChange,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _resendCooldown > 0 ? null : _resendCode,
                          icon: Icon(
                            _resendCooldown > 0
                                ? Icons.hourglass_empty
                                : Icons.refresh_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _resendCooldown > 0
                                ? 'Resend in $_resendCooldown s'
                                : 'Resend code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_emailState == _EmailChangeState.verified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.successContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tokens.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: tokens.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage ?? 'Email updated successfully.',
                            style: TextStyle(
                              color: tokens.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tokens.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: tokens.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_emailState == _EmailChangeState.idle ||
                    _emailState == _EmailChangeState.cancelled)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: _savingProfile ? null : _saveProfile,
                      child:
                          _savingProfile
                              ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      tokens.onPrimary,
                                ),
                              )
                              : Text(
                                _emailChanged
                                    ? 'Save profile changes'
                                    : 'Save changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: tokens.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
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
}

class _EmailFieldCard extends StatefulWidget {
  const _EmailFieldCard({
    required this.controller,
    required this.label,
    required this.icon,
    required this.emailState,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final _EmailChangeState emailState;

  @override
  State<_EmailFieldCard> createState() => _EmailFieldCardState();
}

class _EmailFieldCardState extends State<_EmailFieldCard> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isChanging =
        widget.emailState == _EmailChangeState.reauthRequired ||
        widget.emailState == _EmailChangeState.sending ||
        widget.emailState == _EmailChangeState.sent ||
        widget.emailState == _EmailChangeState.verifying;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isChanging ? tokens.warningContainer : tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isChanging
                  ? tokens.warning.withValues(alpha: 0.35)
                  : tokens.borderSubtle,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        enabled: !isChanging,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: isChanging ? tokens.warning : tokens.primary,
          ),
          labelText: widget.label,
          labelStyle: TextStyle(
            color: isChanging ? tokens.warning : tokens.textSecondary,
          ),
          border: InputBorder.none,
          helperText:
              isChanging
                  ? 'Complete verification before changing your email'
                  : null,
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: tokens.primary),
          labelText: label,
          labelStyle: TextStyle(color: tokens.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
