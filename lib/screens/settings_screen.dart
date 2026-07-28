import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../services/backend_api.dart';
import '../services/push_notification_service.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<UserProfile>? _profileFuture;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendApi.instance.getUserProfile();
  }

  Future<void> _toggleFridayReminder(UserProfile profile, bool value) async {
    setState(() => _savingReminder = true);
    try {
      if (value && !await PushNotificationService.instance.enableForReminders()) {
        throw StateError('Notification permission is required to enable reminders.');
      }
      await BackendApi.instance.updatePreferences(fridayReminder: value);
      if (!mounted) return;
      setState(() => _profileFuture = BackendApi.instance.getUserProfile());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: SnackBar(content: Text(error.toString()))));
      }
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kInk, size: 19),
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
              child: FutureBuilder<UserProfile>(
                future: _profileFuture,
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
                      title: const Text('Friday reminder', style: TextStyle(color: kInk, fontSize: 15, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading your preference...'
                            : 'Get a gentle Friday reminder when it is enabled.',
                        style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
                      ),
                      value: enabled,
                      onChanged: _savingReminder || profile == null ? null : (value) => _toggleFridayReminder(profile, value),
                      activeThumbColor: kBronze,
                    ),
                  );
                },
              ),
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
              child: _SettingsCard(icon: Icons.palette_outlined, title: 'Appearance', subtitle: 'Use your device setting', onTap: null, enabled: false),
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
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

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
    final accent = emphasizeDanger ? kDanger : kBronze;
    return Material(
      color: kPaper,
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
                  color: enabled ? accent.withValues(alpha: 0.12) : kLine,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: enabled ? accent : kMutedLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: enabled ? kInk : kMutedLight, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: enabled ? kMuted : kMutedLight, fontSize: 12.5)),
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
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
