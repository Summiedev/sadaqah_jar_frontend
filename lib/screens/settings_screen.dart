import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/backend_api.dart';

const _ink = Color(0xFF2F241E);
const _muted = Color(0xFF6D5B4D);
const _mutedLight = Color(0xFF9A8A7A);
const _bronze = Color(0xFF8B6842);
const _paper = Color(0xFFFFFCF8);
const _line = Color(0xFFE8DDD1);
const _surface = Color(0xFFF9F4ED);
const _danger = Color(0xFFA8554E);

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
      backgroundColor: _surface,
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
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your profile and preferences.',
                        style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
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
                      color: _paper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _line),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Friday reminder', style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading your preference...'
                            : 'Get a gentle Friday reminder when it is enabled.',
                        style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
                      ),
                      value: enabled,
                      onChanged: _savingReminder || profile == null ? null : (value) => _toggleFridayReminder(profile, value),
                      activeThumbColor: _bronze,
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const SnackBar(content: Text('Password changes are coming soon.'))));
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Appearance',
              subtitle: 'How Mizan looks',
              child: _SettingsCard(icon: Icons.palette_outlined, title: 'Appearance', subtitle: 'Use your device setting', onTap: () {}),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Family',
              subtitle: 'Shared spaces',
              child: _SettingsCard(icon: Icons.groups_outlined, title: 'Family preferences', subtitle: 'Manage invitations and sharing', onTap: () {}),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Support',
              subtitle: 'Help and product information',
              child: Column(children: [
                _SettingsCard(icon: Icons.help_outline, title: 'Help', subtitle: 'Get support', onTap: () {}),
                const SizedBox(height: 10),
                _SettingsCard(icon: Icons.info_outline, title: 'About', subtitle: 'Mizan version and legal', onTap: () {}),
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
              color: _bronze,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasizeDanger;

  @override
  Widget build(BuildContext context) {
    final accent = emphasizeDanger ? _danger : _bronze;
    return Material(
      color: _paper,
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
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _mutedLight, size: 18),
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
        backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        title: const Text('Settings', style: TextStyle(color: _ink, fontFamily: 'Georgia', fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: _ink),
      ),
        body: const Center(child: CircularProgressIndicator(color: _bronze)),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit profile', style: TextStyle(color: _ink)),
        iconTheme: const IconThemeData(color: _ink),
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
                  color: _paper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5C0),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _avatarData != null && _avatarData!.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.memory(base64Decode(_avatarData!), fit: BoxFit.cover))
                            : const Icon(Icons.person, color: Color(0xFF6D4C35), size: 40),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18, color: _bronze),
                      label: const Text('Change avatar', style: TextStyle(color: _bronze, fontWeight: FontWeight.w600)),
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
                    backgroundColor: _bronze,
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
        color: _paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _bronze),
          labelText: label,
          labelStyle: const TextStyle(color: _muted),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
