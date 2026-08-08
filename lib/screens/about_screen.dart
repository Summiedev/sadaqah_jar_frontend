import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('About', style: TextStyle(color: kInk)),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPaper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kLine),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kSoftBronze,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.auto_awesome_outlined, color: kBronze, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mizan',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ميزان',
                    style: TextStyle(
                      fontSize: 18,
                      color: kMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 13, color: kMutedLight),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: kLine),
                  const SizedBox(height: 20),
                  const Text(
                    'A quieter way to give.',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: kBronze,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mizan helps you keep the small acts of goodness that matter - gently, privately, and with intention. '
                    'It is a space for quiet reflection, away from comparison and public feeds.',
                    style: TextStyle(fontSize: 14, color: kMuted, height: 1.65),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kPaper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(icon: Icons.add_circle_outline_rounded, text: 'Track daily acts of goodness'),
                  _FeatureRow(icon: Icons.local_fire_department_outlined, text: 'Build a gentle streak'),
                  _FeatureRow(icon: Icons.volunteer_activism_outlined, text: 'Visual sadaqah jar'),
                  _FeatureRow(icon: Icons.groups_outlined, text: 'Family sharing and goals'),
                  _FeatureRow(icon: Icons.menu_book_outlined, text: 'Adhkar and reflections'),
                  _FeatureRow(icon: Icons.book_outlined, text: 'Islamic library'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kPaper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your data belongs to you. Mizan is designed as a private space. '
                    'Your reflections, acts, and personal information are not shared publicly. '
                    'Family features are opt-in and fully controlled by you.',
                    style: TextStyle(fontSize: 13, color: kMuted, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Made with ❤️ for the Ummah',
                    style: TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'MIZAN • PRIVATE JOURNAL',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: kStonePale,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kSoftBronze,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kBronze, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: kInk, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}