import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../widgets/motion.dart';
import '../home/home_screen.dart';
import '../home/add_act_screen.dart';
import '../journey/journey_screen.dart';
import '../family/family_screen.dart';
import '../profile/profile_screen.dart';

/// Page indices are stable so the PageView controller never has to be recreated
/// when the visible tab set changes with the mode.
const int _kHome = 0;
const int _kJourney = 1;
const int _kFamily = 2;
const int _kProfile = 3;

class _NavDef {
  const _NavDef(this.page, this.icon, this.selectedIcon, this.label, this.location);
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

class _AppShellState extends ConsumerState<AppShell> {
  late final PageController _pageController;
  int _index = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    JourneyScreen(),
    FamilyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _index = _indexFromLocation(GoRouterState.of(context).uri.path);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _indexFromLocation(String location) {
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
          _NavDef(_kJourney, Icons.route_outlined, Icons.route, 'Journey', '/journey'),
          _NavDef(_kProfile, Icons.person_outline, Icons.person, 'Profile', '/profile'),
        ];
      case kModeFamily:
        return const [
          _NavDef(_kFamily, Icons.groups_outlined, Icons.groups, 'Family', '/family'),
          _NavDef(_kJourney, Icons.route_outlined, Icons.route, 'Journey', '/journey'),
          _NavDef(_kProfile, Icons.person_outline, Icons.person, 'Profile', '/profile'),
        ];
      default:
        return const [
          _NavDef(_kHome, Icons.spa_outlined, Icons.spa, 'Sanctuary', '/home'),
          _NavDef(_kJourney, Icons.route_outlined, Icons.route, 'Journey', '/journey'),
          _NavDef(_kFamily, Icons.groups_outlined, Icons.groups, 'Family', '/family'),
          _NavDef(_kProfile, Icons.person_outline, Icons.person, 'Profile', '/profile'),
        ];
    }
  }

  void _goTo(_NavDef tab) {
    _pageController.animateToPage(
      tab.page,
      duration: motionEnabled(context) ? const Duration(milliseconds: 280) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
    context.go(tab.location);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final tabs = _visibleTabs(mode);
    final isScrolled = ref.watch(isScrolledProvider);

return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != _kHome) {
          final home = tabs.firstWhere((tab) => tab.page == _kHome, orElse: () => tabs.first);
          _goTo(home);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const Text('You are already on your home screen.')));
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _index = i),
          children: _pages.map((p) => _KeepAlivePage(key: ValueKey(p.runtimeType), child: p)).toList(),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 82,
          elevation: 0,
          color: isScrolled ? kClayLight : kSurface,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: _DockedNavBar(
            tabs: tabs,
            selectedPage: _index,
            onTap: _goTo,
            onAdd: () => AddActScreen.show(context),
          ),
        ),
      ),
    );
  }
}

class _DockedNavBar extends StatelessWidget {
  const _DockedNavBar({required this.tabs, required this.selectedPage, required this.onTap, this.onAdd});
  final List<_NavDef> tabs;
  final int selectedPage;
  final ValueChanged<_NavDef> onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (tabs.length == 4) {
      final left = tabs.take(2);
      final right = tabs.skip(2);
      return Row(children: [
        for (final tab in left) Expanded(child: _DockedNavItem(tab: tab, selected: tab.page == selectedPage, onTap: () => onTap(tab))),
        if (onAdd != null) _DockedAddButton(onAdd: onAdd!),
        const SizedBox(width: 16),
        for (final tab in right) Expanded(child: _DockedNavItem(tab: tab, selected: tab.page == selectedPage, onTap: () => onTap(tab))),
      ]);
    }
    return Row(children: [
      for (final tab in tabs) Expanded(child: _DockedNavItem(tab: tab, selected: tab.page == selectedPage, onTap: () => onTap(tab))),
      if (onAdd != null) ...[
        const SizedBox(width: 8),
        _DockedAddButton(onAdd: onAdd!),
        const SizedBox(width: 8),
      ],
    ]);
  }
}

class _DockedAddButton extends StatelessWidget {
  const _DockedAddButton({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return PressableSpring(
      scale: .92,
      onTap: onAdd,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: kBronze, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _DockedNavItem extends StatelessWidget {
  const _DockedNavItem({required this.tab, required this.selected, required this.onTap});
  final _NavDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kBronze : kMutedLight;
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
            decoration: BoxDecoration(color: selected ? const Color(0x148B6842) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedScale(
                duration: MizanMotion.normal,
                curve: MizanMotion.gentle,
                scale: selected && motionEnabled(context) ? 1.08 : 1,
                child: Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 23),
              ),
              const SizedBox(height: 4),
              Text(tab.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w700)),
            ]),
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

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
