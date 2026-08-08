import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
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
import 'features/family/family_members_screen.dart';
import 'features/family/family_screen.dart';
import 'features/family/family_settings_screen.dart';
import 'core/route_transitions.dart';
import 'features/family/family_timeline_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journey/journey_screen.dart';
import 'features/journey/morning_adhkar_screen.dart';
import 'features/journey/evening_adhkar_screen.dart';
import 'features/journey/after_salah_adhkar_screen.dart';
import 'features/journey/books_list_screen.dart';
import 'features/qibla/qibla_screen.dart';
import 'features/mode/mode_selection_screen.dart';
import 'features/goals/goal_onboarding_screen.dart';
import 'features/goals/edit_goal_screen.dart';
import 'features/goals/monthly_review_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'screens/admin/admin_route_gate.dart';
import 'screens/notification_center_screen.dart';
import 'screens/settings_screen.dart' hide EditGoalScreen;
import 'screens/charities_list_screen.dart';
import 'services/lock_screen_widget_service.dart';
import 'services/next_prayer_widget_service.dart';
import 'services/offline_action_queue.dart';
import 'services/push_notification_service.dart';
import 'services/local_reminder_service.dart';
import 'services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

/// Minimum time the splash screen must stay visible, regardless of how fast
/// session/auth resolution finishes. Without this, a cached session can
/// resolve in a few milliseconds and the router redirects away before the
/// splash entrance animation gets a single frame. Keep this in sync with
/// the entrance AnimationController duration in SplashScreen.
const splashMinDuration = Duration(milliseconds: 1800);

/// Flips to true once [splashMinDuration] has elapsed since app start.
final splashMinElapsedProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Register background message handler so data-only messages are
  // persisted while the app is backgrounded/terminated.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // If the app was launched from a terminated state via a notification,
  // getInitialMessage() will return that message. Persist its data so the
  // existing startup routing path can handle it uniformly.
  try {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final data = initial.data;
      if (data.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'pending_notification_payload',
          data.entries.map((e) => '${e.key}=${e.value}').join('&'),
        );
      }
    }
  } catch (_) {}
  await OfflineActionQueue.instance.initialize();
  await LockScreenWidgetService.instance.initialize();
  await NextPrayerWidgetService.instance.start();
  final initialThemeMode = await loadInitialThemeMode();
  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(initialThemeMode)],
      child: const MizanApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final minElapsed = ref.watch(splashMinElapsedProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;

      // Never leave /splash until the minimum duration has elapsed, no
      // matter how quickly session status resolves.
      if (!minElapsed) {
        return path == '/splash' ? null : '/splash';
      }

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
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder:
            (context, state) => mizanPage(child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/mode',
        pageBuilder:
            (context, state) => mizanPage(child: const ModeSelectionScreen()),
      ),
      GoRoute(
        path: '/goal-onboarding',
        pageBuilder:
            (context, state) => mizanPage(child: const GoalOnboardingScreen()),
      ),
      GoRoute(
        path: '/monthly-review',
        pageBuilder:
            (context, state) => mizanPage(child: const MonthlyReviewScreen()),
      ),
      GoRoute(
        path: '/goals/edit',
        pageBuilder:
            (context, state) => mizanPage(child: const EditGoalScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => mizanPage(child: const AuthScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder:
            (context, state) => mizanPage(
              child: ForgotPasswordScreen(onBack: () => context.pop()),
            ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder:
            (context, state) => mizanPage(
              child: ResetPasswordScreen(onBack: () => context.pop()),
            ),
      ),
      GoRoute(
        path: '/verification',
        pageBuilder:
            (context, state) => mizanPage(
              child: VerificationScreen(
                onContinue: () => context.go('/auth'),
                onLogin: () => context.go('/auth'),
              ),
            ),
      ),
      GoRoute(
        path: '/charities',
        pageBuilder:
            (context, state) => mizanPage(child: const CharitiesListScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder:
            (context, state) =>
                mizanPage(child: const NotificationCenterScreen()),
      ),
      GoRoute(
        path: '/journey/adhkar/morning',
        pageBuilder:
            (context, state) => mizanPage(
              child: const _AdhkarStandalonePage(
                title: 'Morning Adhkar',
                child: MorningAdhkarList(),
              ),
            ),
      ),
      GoRoute(
        path: '/journey/adhkar/evening',
        pageBuilder:
            (context, state) => mizanPage(
              child: const _AdhkarStandalonePage(
                title: 'Evening Adhkar',
                child: EveningAdhkarList(),
              ),
            ),
      ),
      GoRoute(
        path: '/journey/adhkar/after_salah',
        pageBuilder:
            (context, state) => mizanPage(
              child: const _AdhkarStandalonePage(
                title: 'After Salah',
                child: AfterSalahAdhkarList(),
              ),
            ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder:
            (context, state) => mizanPage(
              child: SettingsScreen(
                onLogout: () async {
                  await ref.read(sessionProvider).signOut();
                  if (context.mounted) context.go('/auth');
                },
              ),
            ),
      ),
      ShellRoute(
        builder: (context, state, child) => const AppShell(),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/qibla',
            builder: (context, state) => const QiblaScreen(),
          ),
          GoRoute(
            path: '/journey',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final initialTab = tab == 'quran' ? 2 : 0;
              final surah = int.tryParse(
                state.uri.queryParameters['surah'] ?? '',
              );
              return JourneyScreen(
                initialTab: initialTab,
                initialQuranSurahId: surah,
              );
            },
          ),
          GoRoute(
            path: '/books',
            builder: (context, state) => const BooksListScreen(),
          ),
          GoRoute(
            path: '/family',
            builder: (context, state) => const FamilyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/family/jar/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: FamilyJarScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/timeline/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: ActivityTimelineScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/goals/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: SharedGoalsScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/reflections/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: FamilyReflectionsScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/prayers/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: PrayerRequestsScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/invitations',
        pageBuilder:
            (context, state) => mizanPage(child: const InvitationsScreen()),
      ),
      GoRoute(
        path: '/family/invitations/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: InvitationsScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/members/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: FamilyMembersScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/family/settings/:id',
        pageBuilder:
            (context, state) => mizanPage(
              child: FamilySettingsScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder:
            (context, state) =>
                mizanPage(child: const AdminRouteGate(routeName: '/admin')),
      ),
      GoRoute(
        path: '/admin/charities',
        pageBuilder:
            (context, state) => mizanPage(
              child: const AdminRouteGate(routeName: '/admin/charities'),
            ),
      ),
      GoRoute(
        path: '/admin/evidence',
        pageBuilder:
            (context, state) => mizanPage(
              child: const AdminRouteGate(routeName: '/admin/evidence'),
            ),
      ),
      GoRoute(
        path: '/admin/analytics',
        pageBuilder:
            (context, state) => mizanPage(
              child: const AdminRouteGate(routeName: '/admin/analytics'),
            ),
      ),
      GoRoute(
        path: '/admin/books',
        pageBuilder:
            (context, state) => mizanPage(
              child: const AdminRouteGate(routeName: '/admin/books'),
            ),
      ),
    ],
  );
});

class _AdhkarStandalonePage extends StatelessWidget {
  const _AdhkarStandalonePage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? kScaffoldDark : kIvory,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: dark ? kSurfaceDark : kClayLight,
        foregroundColor: dark ? kInkDark : kInk,
        surfaceTintColor: Colors.transparent,
      ),
      body: child,
    );
  }
}

class MizanApp extends ConsumerStatefulWidget {
  const MizanApp({super.key});

  @override
  ConsumerState<MizanApp> createState() => _MizanAppState();
}

class _MizanAppState extends ConsumerState<MizanApp>
    with WidgetsBindingObserver {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Start the minimum-splash-duration clock the moment the app launches,
    // independent of how fast session/auth resolution completes.
    _splashTimer = Timer(splashMinDuration, () {
      if (mounted) {
        ref.read(splashMinElapsedProvider.notifier).state = true;
      }
    });
    // Initialize local services: reminders and location
    LocalReminderService.instance.initialize();
    // Initialize push notifications: register token + foreground listeners
    // if permission is already granted; otherwise prepare for opt-in later.
    unawaited(PushNotificationService.instance.initialize());
    // Try to warm location permission state
    LocationService.instance.getStoredPosition();
    // Observe lifecycle to consume pending notifications on resume
    WidgetsBinding.instance.addObserver(this);
    // Consume any pending notification after first frame so routing/context are available
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _consumePendingNotification(),
    );
    // Listen for foreground messages and show an in-app banner (SnackBar)
    PushNotificationService.instance.onForegroundMessage.listen((message) {
      final notification = message.notification;
      final data = message.data;
      final path = data['deep_link'] ?? data['path'] ?? data['link'];
      if (notification != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${notification.title ?? ''}\n${notification.body ?? ''}',
              ),
              action:
                  path != null
                      ? SnackBarAction(
                        label: 'Open',
                        onPressed: () {
                          if (mounted && path.isNotEmpty)
                            GoRouter.of(context).go(path);
                        },
                      )
                      : null,
              duration: const Duration(seconds: 6),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    // cancel any subscriptions in PushNotificationService if needed
    WidgetsBinding.instance.removeObserver(this);
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumePendingNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mizan',
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }

  Future<void> _consumePendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = prefs.getString('pending_notification_payload');
      if (payload != null && payload.isNotEmpty) {
        // Clear it so we don't process twice
        await prefs.remove('pending_notification_payload');
        // Basic parsing: support payloads like "path=/family/jar/1" or key=val&key2=val2
        final parts = <String, String>{};
        if (payload.contains('&') || payload.contains('=')) {
          for (final pair in payload.split('&')) {
            final kv = pair.split('=');
            if (kv.length == 2) parts[kv[0]] = kv[1];
          }
        } else if (payload.startsWith('/')) {
          parts['path'] = payload;
        }
        final path = parts['path'] ?? parts['url'] ?? parts['link'];
        if (path != null && path.isNotEmpty && mounted) {
          // Use GoRouter to navigate now that the first frame has rendered
          if (mounted) GoRouter.of(context).go(path);
        }
      }
    } catch (_) {}
  }
}
