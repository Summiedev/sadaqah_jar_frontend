import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../home/home_screen.dart';
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
  const _NavDef(this.page, this.icon, this.label);
  final int page;
  final IconData icon;
  final String label;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
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
          _NavDef(_kHome, Icons.auto_awesome, 'Sanctuary'),
          _NavDef(_kJourney, Icons.explore_outlined, 'Journey'),
          _NavDef(_kProfile, Icons.person_outline, 'You'),
        ];
      case kModeFamily:
        return const [
          _NavDef(_kFamily, Icons.groups_outlined, 'Family'),
          _NavDef(_kJourney, Icons.explore_outlined, 'Journey'),
          _NavDef(_kProfile, Icons.person_outline, 'You'),
        ];
      default:
        return const [
          _NavDef(_kHome, Icons.auto_awesome, 'Sanctuary'),
          _NavDef(_kJourney, Icons.explore_outlined, 'Journey'),
          _NavDef(_kFamily, Icons.groups_outlined, 'Family'),
          _NavDef(_kProfile, Icons.person_outline, 'You'),
        ];
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final tabs = _visibleTabs(mode);
    final mid = tabs.length ~/ 2;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children: _pages.map((p) => _KeepAlivePage(key: ValueKey(p.runtimeType), child: p)).toList(),
      ),
      bottomNavigationBar: Container(
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E9DE),
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i == mid)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      elevation: 2,
                      backgroundColor: const Color(0xFF8B6842),
                      onPressed: () => context.go('/add-act'),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ),
              _NavItem(
                active: _index == tabs[i].page,
                icon: tabs[i].icon,
                label: tabs[i].label,
                onTap: () => _goTo(tabs[i].page),
              ),
            ],
          ],
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

class _NavItem extends StatelessWidget {
  const _NavItem({required this.active, required this.icon, required this.label, required this.onTap});

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8B6842) : const Color(0xFFB08D73);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
