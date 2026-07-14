import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/prototype_skeleton.dart';
import '../../core/mode_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 700));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: PrototypeSkeleton(
                  children: [
                    SkeletonLine(width: 120, height: 12),
                    SizedBox(height: 14),
                    SkeletonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 180, height: 16),
                          SizedBox(height: 12),
                          SkeletonLine(width: double.infinity, height: 56, radius: 16),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                    SkeletonCard(child: SkeletonLine(width: double.infinity, height: 180, radius: 18)),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: const [
                _HeaderRow(),
                SizedBox(height: 14),
                _CompanionModesCard(),
                SizedBox(height: 14),
                _AlertsCard(),
                SizedBox(height: 14),
                _PrivacyCard(),
                SizedBox(height: 14),
                _SettingsCard(),
                SizedBox(height: 18),
                Center(
                  child: Text(
                    'MIZAN • PRIVATE JOURNAL',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA28F7F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'MIZAN • Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2F241E)),
          ),
        ),
        const Text(
          'RAMADAN MODE',
          style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Color(0xFFB38964)),
        ),
      ],
    );
  }
}

class _CompanionModesCard extends ConsumerWidget {
  const _CompanionModesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    return _SectionCard(
      title: 'Active Companion Mode',
      trailing: 'TAILORED UI',
      child: Column(
        children: [
          _ChoiceTile(
            icon: Icons.person_outline,
            color: const Color(0xFF9A6A3A),
            title: 'Personal Sanctuary (Sajid)',
            body: 'Pages and widgets tailored to solitary remembrance, private reflections, and personal goals.',
            selected: mode == 0,
            onTap: () => ref.read(modeProvider.notifier).setMode(0),
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            icon: Icons.groups_outlined,
            color: const Color(0xFF1FA36B),
            title: 'Family Household (Yusr)',
            body: 'Pages and widgets tailored to cooperative family jars, household members, and the communal sanctuary.',
            selected: mode == 1,
            onTap: () => ref.read(modeProvider.notifier).setMode(1),
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            icon: Icons.auto_awesome_outlined,
            color: const Color(0xFF4A8DF7),
            title: 'Integrated Balanced (Mizan)',
            body: 'Full experience of both private individual remembrance and shared household devotions.',
            selected: mode == 2,
            onTap: () => ref.read(modeProvider.notifier).setMode(2),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Alert Customization',
      trailing: '',
      child: Column(
        children: const [
          _ToggleRow(label: 'Fajr Dawn Reminder', value: true),
          Divider(height: 1, color: Color(0xFFE8DCCA)),
          _ToggleRow(label: 'Friday Jumu\'ah Call', value: true),
          Divider(height: 1, color: Color(0xFFE8DCCA)),
          _ToggleRow(label: 'Silent Contemplation Mode', value: true),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Data Ledger Privacy',
      trailing: '',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mizan does not operate standard analytics tracking pixels, remote database synchronizers, or social feed layers. Your ledger is stored only on this physical handset.',
            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF6D5B4D)),
          ),
          SizedBox(height: 14),
          _ActionRow(icon: Icons.download_outlined, label: 'Export Data Ledger'),
          SizedBox(height: 10),
          _ActionRow(icon: Icons.lock_outline, label: 'Privacy & Security'),
          SizedBox(height: 10),
          _ActionRow(icon: Icons.family_restroom, label: 'Family Invitations'),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Preferences',
      trailing: '',
      child: const Column(
        children: [
          _ActionRow(icon: Icons.brightness_6_outlined, label: 'Theme'),
          SizedBox(height: 10),
          _ActionRow(icon: Icons.notifications_outlined, label: 'Notification Preferences'),
          SizedBox(height: 10),
          _ActionRow(icon: Icons.info_outline, label: 'About Mizan'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.trailing, required this.child});

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D3C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
              ),
              if (trailing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(trailing, style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Color(0xFFA28F7F))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.icon, required this.color, required this.title, required this.body, this.selected = false, this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF7F2EA) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFF1FA36B) : const Color(0xFFE3D3C3), width: selected ? 1.4 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                    const SizedBox(height: 3),
                    Text(body, style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF9A8A7A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2F241E))),
          ),
          Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: const Color(0xFF8B6842)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCA)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B6842)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF2F241E)))),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB08D73)),
        ],
      ),
    );
  }
}
