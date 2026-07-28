import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: kClayLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminTile(
            icon: Icons.menu_book_outlined,
            title: 'Books',
            subtitle: 'Manage Islamic library books and chapters',
            onTap: () => context.push('/admin/books'),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'Charities',
            subtitle: 'Manage charity records and verification status',
            onTap: () => context.push('/admin/charities'),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.menu_book_outlined,
            title: 'Evidence',
            subtitle: 'Review and maintain act evidence entries',
            onTap: () => context.push('/admin/evidence'),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.insights_outlined,
            title: 'Analytics',
            subtitle: 'View admin metrics and live summaries',
            onTap: () => context.push('/admin/analytics'),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
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
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: kBronze),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
