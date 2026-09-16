import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import '../../widgets/mizan_async_state.dart';
import 'admin_analytics_screen.dart';
import 'admin_broadcasts_screen.dart';
import 'admin_books_screen.dart';
import 'admin_charities_screen.dart';
import 'admin_evidence_screen.dart';
import 'admin_home_screen.dart';

class AdminRouteGate extends StatefulWidget {
  const AdminRouteGate({super.key, required this.routeName});

  final String routeName;

  @override
  State<AdminRouteGate> createState() => _AdminRouteGateState();
}

class _AdminRouteGateState extends State<AdminRouteGate> {
  late Future<bool> _isAdmin;

  @override
  void initState() {
    super.initState();
    _reloadAccess();
  }

  void _reloadAccess() {
    _isAdmin = BackendApi.instance.isCurrentUserAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: MizanLoadingState(label: 'Checking access...'),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Access')),
            body: MizanErrorState(
              message: backendErrorMessage(
                snapshot.error,
                fallback: 'We could not verify admin access right now.',
              ),
              onRetry: () {
                setState(_reloadAccess);
              },
            ),
          );
        }

        final isAdmin = snapshot.data == true;
        if (!isAdmin) {
          return const AdminForbiddenScreen();
        }

        switch (widget.routeName) {
          case '/admin/charities':
            return const AdminCharitiesScreen();
          case '/admin/evidence':
            return const AdminEvidenceScreen();
          case '/admin/analytics':
            return const AdminAnalyticsScreen();
          case '/admin/books':
            return const AdminBooksScreen();
          case '/admin/broadcasts':
            return const AdminBroadcastsScreen();
          case '/admin':
          default:
            return const AdminHomeScreen();
        }
      },
    );
  }
}

class AdminForbiddenScreen extends StatelessWidget {
  const AdminForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: context.colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '403 - Admin access required',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This route is reserved for administrators.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
