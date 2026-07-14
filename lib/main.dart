import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/family/family_invitations_screen.dart';
import 'features/family/family_jar_screen.dart';
import 'features/family/family_goals_screen.dart';
import 'features/family/family_prayers_screen.dart';
import 'features/family/family_reflections_screen.dart';
import 'features/family/family_screen.dart';
import 'features/family/family_settings_screen.dart';
import 'features/family/family_theme.dart';
import 'features/family/family_timeline_screen.dart';
import 'features/home/add_act_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journey/journey_screen.dart';
import 'features/mode/mode_selection_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: MizanApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/mode', builder: (context, state) => const ModeSelectionScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/add-act', builder: (context, state) => const AddActScreen()),
      ShellRoute(
        builder: (context, state, child) => const AppShell(),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/journey', builder: (context, state) => const JourneyScreen()),
          GoRoute(path: '/family', builder: (context, state) => const FamilyScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/family/jar/:id',
        pageBuilder: (context, state) => mizanPage(child: FamilyJarScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/timeline/:id',
        pageBuilder: (context, state) => mizanPage(child: ActivityTimelineScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/goals/:id',
        pageBuilder: (context, state) => mizanPage(child: SharedGoalsScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/reflections/:id',
        pageBuilder: (context, state) => mizanPage(child: FamilyReflectionsScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/prayers/:id',
        pageBuilder: (context, state) => mizanPage(child: PrayerRequestsScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/invitations',
        pageBuilder: (context, state) => mizanPage(child: const InvitationsScreen()),
      ),
      GoRoute(
        path: '/family/invitations/:id',
        pageBuilder: (context, state) => mizanPage(child: InvitationsScreen(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/family/settings/:id',
        pageBuilder: (context, state) => mizanPage(child: FamilySettingsScreen(id: state.pathParameters['id']!)),
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
