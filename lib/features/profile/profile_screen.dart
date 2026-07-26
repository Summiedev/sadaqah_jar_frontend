import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';
import '../../services/push_notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _scrolled = false;

  Color get _appBarColor => kClayLight;

  @override
  Widget build(BuildContext context) {
    final selectedMode = ref.watch(modeProvider);

    return Scaffold(
      backgroundColor: kSurface,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final offset = notification.metrics.pixels;
          if (offset > 8 && !_scrolled) {
            setState(() => _scrolled = true);
          } else if (offset <= 4 && _scrolled) {
            setState(() => _scrolled = false);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              toolbarHeight: 64,
              elevation: 0,
              backgroundColor: _appBarColor,
              foregroundColor: kInk,
              surfaceTintColor: Colors.transparent,
              title: const Text('Profile',
                  style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
              actions: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_outlined, color: kInk),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 15),
                    _AccountCard(),
                    const SizedBox(height: 18),
                    _Group(
                      title: 'Your companion',
                      children: [
                        _ModeRow(
                          icon: Icons.spa_outlined,
                          title: 'Personal sanctuary',
                          body: 'For private reflection and remembrance.',
                          mode: kModePersonal,
                          isSelected: selectedMode == kModePersonal,
                        ),
                        _ModeRow(
                          icon: Icons.groups_outlined,
                          title: 'Family home',
                          body: 'For gentle growth with the people you love.',
                          mode: kModeFamily,
                          isSelected: selectedMode == kModeFamily,
                        ),
                        _ModeRow(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Balanced',
                          body: 'Keep both spaces close at hand.',
                          mode: kModeBoth,
                          isSelected: selectedMode == kModeBoth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Group(
                      title: 'Notifications',
                      subtitle: 'Gentle nudges and preferences',
                      child: FutureBuilder<UserProfile>(
                        future: BackendApi.instance.getUserProfile(),
                        builder: (context, snapshot) {
                          final profile = snapshot.data;
                          final enabled = profile?.fridayReminder ?? false;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kPaper,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: kLine),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Friday reminder', style: TextStyle(color: kInk, fontSize: 15, fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                snapshot.connectionState == ConnectionState.waiting
                                    ? 'Loading your preference...'
                                    : 'Get a gentle Friday reminder when it is enabled.',
                                style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
                              ),
                              value: enabled,
                              onChanged: (value) => _toggleFridayReminder(profile, value),
                              activeThumbColor: kBronze,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Group(
                      title: 'Settings',
                      subtitle: 'Reminders and account details',
                      child: _SettingsCard(
                        icon: Icons.tune_outlined,
                        title: 'Settings',
                        subtitle: 'Reminders and account details',
                        onTap: () => context.push('/settings'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AdminPortalTile(),
                    const SizedBox(height: 18),
                    _Group(
                      title: 'About Mizan',
                      subtitle: 'Product information',
                      children: const [
                        _InfoRow(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'MIZAN • PRIVATE JOURNAL',
                        style: TextStyle(fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: kStonePale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFridayReminder(UserProfile? profile, bool value) async {
    if (profile == null) return;
    try {
      if (value && !await PushNotificationService.instance.enableForReminders()) {
        throw StateError('Notification permission is required to enable reminders.');
      }
      await BackendApi.instance.updatePreferences(fridayReminder: value);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: SnackBar(content: Text(error.toString()))));
      }
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: BackendApi.instance.getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPaper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine),
            ),
            child: const Row(children: [
              CircleAvatar(radius: 26, backgroundColor: kClayLight, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Loading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
                SizedBox(height: 3),
                Text('Loading...', style: TextStyle(fontSize: 13, color: kMuted)),
              ])),
            ]),
          );
        }
        final initial = profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kClayLight,
                backgroundImage: profile.avatarData != null && profile.avatarData!.isNotEmpty ? MemoryImage(base64Decode(profile.avatarData!)) : null,
                child: profile.avatarData == null || profile.avatarData!.isEmpty ? Text(initial, style: const TextStyle(color: kBronzeDark, fontWeight: FontWeight.w800, fontSize: 22, fontFamily: 'Georgia')) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kSageSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  profile.emailVerified ? 'Verified' : 'Unverified',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kSage,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    this.subtitle,
    this.child,
    this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: kBronze,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine),
          ),
          child: child ?? Column(children: children ?? const <Widget>[]),
        ),
      ],
    );
  }
}

class _ModeRow extends ConsumerWidget {
  const _ModeRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.mode,
    required this.isSelected,
  });

  final IconData icon;
  final String title;
  final String body;
  final int mode;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(modeProvider.notifier).setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: mode != kModeBoth ? const BorderSide(color: kLine) : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? kSoftBronze : kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? kBronze : kMutedLight,
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
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: kInk,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: kMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: kBronze, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(
        'Mizan is designed to hold space for your intentions, reflections, and quiet acts of goodness — without comparison or a public feed.',
        style: TextStyle(fontSize: 13, height: 1.55, color: kMuted),
      ),
    );
  }
}

class _AdminPortalTile extends StatelessWidget {
  const _AdminPortalTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BackendApi.instance.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;
        if (!isAdmin) return const SizedBox.shrink();
        return _SettingsCard(
          icon: Icons.shield_outlined,
          title: 'Admin Portal',
          subtitle: 'Manage books, charities, evidence, and analytics',
          onTap: () => context.push('/admin'),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = kBronze;
    return Material(
      color: kPaper,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: kMutedLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
