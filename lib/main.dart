import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/session_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/verification_screen.dart';
import 'features/family/family_invitations_screen.dart';
import 'features/family/family_jar_screen.dart';
import 'features/family/family_goals_screen.dart';
import 'features/family/family_prayers_screen.dart';
import 'features/family/family_reflections_screen.dart';
import 'features/family/family_screen.dart';
import 'features/family/family_settings_screen.dart';
import 'core/route_transitions.dart';
import 'features/family/family_timeline_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journey/journey_screen.dart';
import 'features/journey/books_list_screen.dart';
import 'features/mode/mode_selection_screen.dart';
import 'features/goals/goal_onboarding_screen.dart';
import 'features/goals/monthly_review_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'screens/admin/admin_route_gate.dart';
import 'screens/notification_center_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/charities_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MizanApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      if (session.status == SessionStatus.loading) {
        return path == '/splash' ? null : '/splash';
      }
      if (session.isAuthenticated) {
        if (path == '/splash' || path == '/onboarding' || path == '/auth') {
          return session.goalSetupComplete ? '/home' : '/goal-onboarding';
        }
        if (path == '/goal-onboarding' && session.goalSetupComplete) {
          return '/home';
        }
        return null;
      }
      if (!session.onboardingComplete) {
        return path == '/onboarding' ? null : '/onboarding';
      }
      return path == '/auth' ? null : '/auth';
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', pageBuilder: (context, state) => mizanPage(child: const OnboardingScreen())),
      GoRoute(path: '/mode', pageBuilder: (context, state) => mizanPage(child: const ModeSelectionScreen())),
      GoRoute(path: '/goal-onboarding', pageBuilder: (context, state) => mizanPage(child: const GoalOnboardingScreen())),
      GoRoute(path: '/monthly-review', pageBuilder: (context, state) => mizanPage(child: const MonthlyReviewScreen())),
      GoRoute(path: '/auth', pageBuilder: (context, state) => mizanPage(child: const AuthScreen())),
      GoRoute(path: '/forgot-password', pageBuilder: (context, state) => mizanPage(child: ForgotPasswordScreen(onBack: () => context.pop()))),
      GoRoute(path: '/reset-password', pageBuilder: (context, state) => mizanPage(child: ResetPasswordScreen(onBack: () => context.pop()))),
      GoRoute(path: '/verification', pageBuilder: (context, state) => mizanPage(child: VerificationScreen(onContinue: () => context.go('/auth'), onLogin: () => context.go('/auth')))),
      GoRoute(path: '/charities', pageBuilder: (context, state) => mizanPage(child: const CharitiesListScreen())),
      GoRoute(path: '/notifications', pageBuilder: (context, state) => mizanPage(child: const NotificationCenterScreen())),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => mizanPage(child: SettingsScreen(
          onLogout: () async {
            await ref.read(sessionProvider).signOut();
            if (context.mounted) context.go('/auth');
          },
        )),
      ),
      ShellRoute(
        builder: (context, state, child) => const AppShell(),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/journey', builder: (context, state) => const JourneyScreen()),
      GoRoute(path: '/books', builder: (context, state) => const BooksListScreen()),
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
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => mizanPage(child: const AdminRouteGate(routeName: '/admin')),
      ),
      GoRoute(
        path: '/admin/charities',
        pageBuilder: (context, state) => mizanPage(child: const AdminRouteGate(routeName: '/admin/charities')),
      ),
      GoRoute(
        path: '/admin/evidence',
        pageBuilder: (context, state) => mizanPage(child: const AdminRouteGate(routeName: '/admin/evidence')),
      ),
      GoRoute(
        path: '/admin/analytics',
        pageBuilder: (context, state) => mizanPage(child: const AdminRouteGate(routeName: '/admin/analytics')),
      ),
      GoRoute(
        path: '/admin/books',
        pageBuilder: (context, state) => mizanPage(child: const AdminRouteGate(routeName: '/admin/books')),
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
