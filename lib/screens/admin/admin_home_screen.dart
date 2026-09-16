import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/mizan_surface.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        padding: MizanSpacing.screen,
        children: [
          _AdminTile(
            icon: Icons.menu_book_outlined,
            title: 'Books',
            subtitle: 'Upload, preview, publish, and manage reading files',
            onTap: () => context.push('/admin/books'),
          ),
          const SizedBox(height: MizanSpacing.md),
          _AdminTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donations',
            subtitle: 'Manage personal cases and verified external campaigns',
            onTap: () => context.push('/admin/charities'),
          ),
          const SizedBox(height: MizanSpacing.md),
          _AdminTile(
            icon: Icons.menu_book_outlined,
            title: 'Evidence',
            subtitle: 'Review and maintain act evidence entries',
            onTap: () => context.push('/admin/evidence'),
          ),
          const SizedBox(height: MizanSpacing.md),
          _AdminTile(
            icon: Icons.insights_outlined,
            title: 'Analytics',
            subtitle: 'View admin metrics and live summaries',
            onTap: () => context.push('/admin/analytics'),
          ),
          const SizedBox(height: MizanSpacing.md),
          _AdminTile(
            icon: Icons.campaign_outlined,
            title: 'Broadcasts',
            subtitle: 'Create announcements and measure engagement',
            onTap: () => context.push('/admin/broadcasts'),
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
    final colors = context.colors;
    return MizanSurface(
      padding: MizanSpacing.card,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: MizanSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MizanSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.iconSecondary),
        ],
      ),
    );
  }
}
