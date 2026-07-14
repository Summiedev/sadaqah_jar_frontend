import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/backend_api.dart';

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
    setState(() {
      _savingReminder = true;
    });
    try {
      await BackendApi.instance.updatePreferences(fridayReminder: value);
      if (!mounted) return;
      setState(() {
        _profileFuture = BackendApi.instance.getUserProfile();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingReminder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EBDD),
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings', style: TextStyle(color: Color(0xFF3B3327), fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(s(18), s(10), s(18), s(24)),
        children: [
          Container(
            padding: EdgeInsets.all(s(18)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8D7C1), Color(0xFFF7F3ED)],
              ),
              borderRadius: BorderRadius.circular(s(24)),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Polish your experience', style: TextStyle(fontSize: s(22), fontWeight: FontWeight.w900, color: const Color(0xFF2F251E))),
                SizedBox(height: s(6)),
                Text(
                  'Keep your profile, reminders, and account state feeling calm and clear.',
                  style: TextStyle(fontSize: s(13.2), color: const Color(0xFF6A5E52), height: 1.4),
                ),
              ],
            ),
          ),
          SizedBox(height: s(16)),
          _SettingsSection(
            title: 'Account',
            subtitle: 'Profile and identity',
            child: _SettingsCard(
              scale: scale,
              icon: Icons.person_outline,
              title: 'Edit profile',
              subtitle: 'Update your name, email, and avatar',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              },
            ),
          ),
          SizedBox(height: s(14)),
          _SettingsSection(
            title: 'Notifications',
            subtitle: 'Gentle nudges and preferences',
            child: FutureBuilder<UserProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final enabled = profile?.fridayReminder ?? false;
                return Container(
                  padding: EdgeInsets.all(s(14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3ED),
                    borderRadius: BorderRadius.circular(s(18)),
                    border: Border.all(color: const Color(0xFFE6D6C4)),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Friday reminder', style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(15), fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading your preference...'
                          : 'Get a gentle Friday reminder when it is enabled.',
                      style: TextStyle(color: const Color(0xFF7A5B3E), fontSize: s(12.4), height: 1.35),
                    ),
                    value: enabled,
                    onChanged: _savingReminder || profile == null ? null : (value) => _toggleFridayReminder(profile, value),
                    activeThumbColor: const Color(0xFF8B6842),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: s(14)),
          _SettingsSection(
            title: 'Security',
            subtitle: 'Session and access',
            child: _SettingsCard(
              scale: scale,
              icon: Icons.lock_outline,
              title: 'Change password',
              subtitle: 'Secure your account with a new password',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changes are not wired yet.')));
              },
            ),
          ),
          SizedBox(height: s(14)),
          _SettingsSection(
            title: 'Session',
            subtitle: 'Sign out when you are done',
            child: _SettingsCard(
              scale: scale,
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
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
        backgroundColor: const Color(0xFFF2EBDD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2EBDD),
          surfaceTintColor: Colors.transparent,
          title: const Text('Edit profile', style: TextStyle(color: Color(0xFF3B3327))),
          iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EBDD),
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit profile', style: TextStyle(color: Color(0xFF3B3327))),
        iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3ED),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFF8B6842),
                        backgroundImage: _avatarData != null && _avatarData!.isNotEmpty ? MemoryImage(base64Decode(_avatarData!)) : null,
                        child: _avatarData == null || _avatarData!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 42)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Change avatar'),
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6842),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2F251E))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A5B3E))),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasizeDanger = false,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasizeDanger;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final accent = emphasizeDanger ? const Color(0xFFB6544D) : const Color(0xFF8B6842);
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(18)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Row(
            children: [
              Container(
                width: s(42),
                height: s(42),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                child: Icon(icon, color: accent, size: s(22)),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(15), fontWeight: FontWeight.w700)),
                    SizedBox(height: s(3)),
                    Text(subtitle, style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12.5), height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: s(15), color: const Color(0xFF7A5B3E)),
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
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D6C4)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF8B6842)),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}