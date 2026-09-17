import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/session_controller.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/animations.dart';
import '../../core/act_store.dart';
import '../../services/streak_progress_widget_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/queue_sync_service.dart';
import '../../widgets/motion.dart';
import '../home/home_screen.dart';
import '../home/add_act_screen.dart';
import '../journey/journey_screen.dart';
import '../family/family_screen.dart';
import '../profile/profile_screen.dart';
import '../qibla/qibla_screen.dart';
import '../../screens/settings_screen.dart';

/// Page indices are stable so the PageView controller never has to be recreated
/// when the visible tab set changes with the mode.
const int _kHome = 0;
const int _kJourney = 1;
const int _kFamily = 2;
const int _kSettings = 3;
const int _kQibla = 4;
const int _kProfile = 5;

class _NavDef {
  const _NavDef(
    this.page,
    this.icon,
    this.selectedIcon,
    this.label,
    this.location,
  );
  final int page;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String location;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _index = 0;
  ActStore? _observedActStore;

  List<Widget> get _pages => [
    const HomeScreen(),
    const JourneyScreen(),
    const FamilyScreen(),
    SettingsScreen(onLogout: _logout),
    const QiblaScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final store = ref.read(actStoreProvider);
        _observedActStore = store;
        store.addListener(_onActStoreChanged);
        // Logout intentionally clears local user data. Rehydrate the same
        // account's server-backed jar and goal progress when the shell opens
        // again after login or account restoration.
        await store.load();
        StreakProgressWidgetService.instance.update(store);
        ConnectivityService.instance.initialize(
          ref,
          onBecameOnline: _syncQueueBestEffort,
        );
        _syncQueueBestEffort();
      }
    });
  }

  void _syncQueueBestEffort() {
    unawaited(_syncQueue());
  }

  Future<void> _syncQueue() async {
    try {
      await QueueSyncService.instance.attemptSync();
    } catch (_) {
      // A temporary database/network failure is retried by the queue service;
      // it must never become an unhandled lifecycle exception.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _syncQueueBestEffort();
    unawaited(ref.read(actStoreProvider).refresh());
  }

  void _onActStoreChanged() {
    final store = _observedActStore;
    if (store == null || !store.loaded) return;
    StreakProgressWidgetService.instance.update(store);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _index = _indexFromLocation(GoRouterState.of(context).uri.path);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_index);
    }
    final store = ref.read(actStoreProvider);
    StreakProgressWidgetService.instance.update(store);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observedActStore?.removeListener(_onActStoreChanged);
    ConnectivityService.instance.dispose();
    QueueSyncService.instance.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/qibla')) return _kQibla;
    if (location.startsWith('/settings')) return _kSettings;
    if (location.startsWith('/journey')) return _kJourney;
    if (location.startsWith('/family')) return _kFamily;
    if (location.startsWith('/profile')) return _kProfile;
    return _kHome;
  }

  List<_NavDef> _visibleTabs(int mode) {
    switch (mode) {
      case kModePersonal:
        return const [
          _NavDef(_kHome, Icons.spa_outlined, Icons.spa, 'Sanctuary', '/home'),
          _NavDef(
            _kJourney,
            Icons.route_outlined,
            Icons.route,
            'Journey',
            '/journey',
          ),
          _NavDef(
            _kQibla,
            Icons.explore_outlined,
            Icons.explore,
            'Qibla',
            '/qibla',
          ),
          _NavDef(
            _kProfile,
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profile',
            '/profile',
          ),
        ];
      case kModeFamily:
        return const [
          _NavDef(
            _kFamily,
            Icons.groups_outlined,
            Icons.groups,
            'Family',
            '/family',
          ),
          _NavDef(
            _kJourney,
            Icons.route_outlined,
            Icons.route,
            'Journey',
            '/journey',
          ),
          _NavDef(
            _kQibla,
            Icons.explore_outlined,
            Icons.explore,
            'Qibla',
            '/qibla',
          ),
          _NavDef(
            _kProfile,
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profile',
            '/profile',
          ),
        ];
      default:
        return const [
          _NavDef(_kHome, Icons.spa_outlined, Icons.spa, 'Sanctuary', '/home'),
          _NavDef(
            _kJourney,
            Icons.route_outlined,
            Icons.route,
            'Journey',
            '/journey',
          ),
          _NavDef(
            _kFamily,
            Icons.groups_outlined,
            Icons.groups,
            'Family',
            '/family',
          ),
          _NavDef(
            _kQibla,
            Icons.explore_outlined,
            Icons.explore,
            'Qibla',
            '/qibla',
          ),
        ];
    }
  }

  Future<void> _logout() async {
    await ref.read(sessionProvider).signOut();
    if (mounted) context.go('/auth');
  }

  void _goTo(_NavDef tab) {
    _pageController.animateToPage(
      tab.page,
      duration:
          motionEnabled(context)
              ? const Duration(milliseconds: 280)
              : Duration.zero,
      curve: Curves.easeOutCubic,
    );
    context.go(tab.location);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final tabs = _visibleTabs(mode);
    final isScrolled = ref.watch(isScrolledProvider);

    final tokens = context.colors;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children:
            _pages
                .map(
                  (p) => _KeepAlivePage(key: ValueKey(p.runtimeType), child: p),
                )
                .toList(),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 82,
        elevation: 0,
        color: isScrolled ? tokens.surfaceElevated : tokens.surface,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: _DockedNavBar(
          tabs: tabs,
          selectedPage: _index,
          onTap: _goTo,
          onAdd: () => AddActScreen.show(context),
        ),
      ),
    );
  }
}

class _DockedNavBar extends StatelessWidget {
  const _DockedNavBar({
    required this.tabs,
    required this.selectedPage,
    required this.onTap,
    this.onAdd,
  });
  final List<_NavDef> tabs;
  final int selectedPage;
  final ValueChanged<_NavDef> onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (onAdd != null) {
      final left = tabs.take(2);
      final right = tabs.skip(2);
      return Row(
        children: [
          for (final tab in left)
            Expanded(
              child: _DockedNavItem(
                tab: tab,
                selected: tab.page == selectedPage,
                onTap: () => onTap(tab),
              ),
            ),
          _DockedAddButton(onAdd: onAdd!),
          const SizedBox(width: 16),
          for (final tab in right)
            Expanded(
              child: _DockedNavItem(
                tab: tab,
                selected: tab.page == selectedPage,
                onTap: () => onTap(tab),
              ),
            ),
        ],
      );
    }
    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: _DockedNavItem(
              tab: tab,
              selected: tab.page == selectedPage,
              onTap: () => onTap(tab),
            ),
          ),
      ],
    );
  }
}

class _DockedAddButton extends StatelessWidget {
  const _DockedAddButton({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Semantics(
      button: true,
      label: 'Add a sadaqah act',
      child: PressableSpring(
        scale: .92,
        onTap: onAdd,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: tokens.onPrimary, size: 22),
        ),
      ),
    );
  }
}

class _DockedNavItem extends StatelessWidget {
  const _DockedNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });
  final _NavDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = selected ? tokens.primary : tokens.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(18),
        child: PressableSpring(
          onTap: onTap,
          scale: .96,
          child: AnimatedContainer(
            duration: MizanMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              color:
                  selected ? color.withValues(alpha: 0.13) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: MizanMotion.normal,
                  curve: MizanMotion.gentle,
                  scale: selected && motionEnabled(context) ? 1.08 : 1,
                  child: Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Preserves each tab's state across swipes and tab switches.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child, super.key});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
