import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_screen.dart';
import '../features/family/family_screen.dart';
import '../features/home/add_act_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/add-act', builder: (context, state) => const AddActScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/journey', builder: (context, state) => const JourneyScreen()),
          GoRoute(path: '/family', builder: (context, state) => const FamilyScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const _ProfileScreen()),
        ],
      ),
    ],
  );
});

class MizanApp extends ConsumerWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mizan',
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Notifications', Icons.notifications_outlined),
      ('Reminder Schedule', Icons.schedule_outlined),
      ('Appearance', Icons.palette_outlined),
      ('Privacy', Icons.lock_outline),
      ('Export Data Ledger', Icons.download_outlined),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                Text('Settings', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Color(0xFFA28F7F))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFF9F4ED), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE3D3C3))),
              child: const Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Color(0xFFE2D0BE), child: Icon(Icons.person, color: Color(0xFF8B6842))),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Amina', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))), SizedBox(height: 4), Text('Quiet balance seeker', style: TextStyle(fontSize: 12, color: Color(0xFF6D5B4D)))]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFF9F4ED), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE3D3C3))),
                child: Row(
                  children: [
                    Icon(item.$2, color: const Color(0xFF8B6842)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2F241E)))),
                    const Icon(Icons.chevron_right, color: Color(0xFF8B6842)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
            const Text('Mizan Companion • Built in Sincerity', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: Color(0xFFA28F7F), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}