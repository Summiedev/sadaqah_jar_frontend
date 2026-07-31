import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode_provider.dart';
import '../../core/session_controller.dart';
import '../family/family_theme.dart' show FamilyJarView;

const _ink = Color(0xFF30261F);
const _bronze = Color(0xFF8B6842);
const _muted = Color(0xFF76695E);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  late final PageController _pages = PageController();
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  int _page = 0;
  int _mode = kModeBoth;

  @override
  void dispose() { _pages.dispose(); _breath.dispose(); super.dispose(); }

  Future<void> _next() async {
    if (_page < 2) {
      await _pages.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
      return;
    }
    await ref.read(modeProvider.notifier).setMode(_mode);
    await ref.read(sessionProvider).completeOnboarding();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _breath,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFF9F3EB), Color.lerp(const Color(0xFFF4E5D2), const Color(0xFFF8F3EC), _breath.value)!, const Color(0xFFF2E9DD)])),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 18, 20, 0), child: Row(children: [const Text('MIZAN', style: TextStyle(color: _bronze, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 3.5)), const Spacer(), if (_page < 2) TextButton(onPressed: () { _pages.animateToPage(2, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic); }, child: const Text('Skip', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)))])),
          Expanded(child: PageView(controller: _pages, onPageChanged: (value) => setState(() => _page = value), children: [_Welcome(breath: _breath), const _WhyMizan(), _ChooseMode(selected: _mode, onSelect: (value) => setState(() => _mode = value))])),
          Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 28), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => AnimatedContainer(duration: const Duration(milliseconds: 240), margin: const EdgeInsets.symmetric(horizontal: 4), width: _page == index ? 26 : 7, height: 7, decoration: BoxDecoration(color: _page == index ? _bronze : const Color(0xFFD7C6B4), borderRadius: BorderRadius.circular(99))))), const SizedBox(height: 22), SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(_page == 2 ? 'Begin with Mizan' : 'Continue')))])),
        ])),
      ),
    ),
  );
}

class _Welcome extends StatelessWidget { const _Welcome({required this.breath}); final Animation<double> breath; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [AnimatedBuilder(animation: breath, builder: (context, child) => Transform.translate(offset: Offset(0, -5 * breath.value), child: child), child: const SizedBox(width: 190, height: 210, child: FamilyJarView(fill: .42, size: 156, glow: .95))), const SizedBox(height: 28), const Text('A quieter way\nto give.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Georgia', fontSize: 34, height: 1.08, fontWeight: FontWeight.w700, color: _ink)), const SizedBox(height: 14), const Text('Mizan helps you keep the small acts of goodness that matter — gently, privately, and with intention.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.55, color: _muted))])); }

class _WhyMizan extends StatelessWidget { const _WhyMizan(); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Small acts\nbecome a life.', style: TextStyle(fontFamily: 'Georgia', fontSize: 33, height: 1.1, color: _ink, fontWeight: FontWeight.w700)), const SizedBox(height: 28), const _Rhythm(icon: Icons.add_circle_outline_rounded, title: 'Notice the good', body: 'Save a kind act, a gift, or a prayer in a few seconds.'), const SizedBox(height: 16), const _Rhythm(icon: Icons.local_fire_department_outlined, title: 'Build a gentle rhythm', body: 'Your streak celebrates return, never perfection.'), const SizedBox(height: 16), const _Rhythm(icon: Icons.volunteer_activism_outlined, title: 'Watch your jar grow', body: 'A clear, meaningful picture of the goodness you are gathering.') ])); }
class _Rhythm extends StatelessWidget { const _Rhythm({required this.icon, required this.title, required this.body}); final IconData icon; final String title, body; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xCCFFFCF8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8D8C7))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFF2E5D6), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: _bronze)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.35))]))])); }
class _ChooseMode extends StatelessWidget { const _ChooseMode({required this.selected, required this.onSelect}); final int selected; final ValueChanged<int> onSelect; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Make it yours.', style: TextStyle(fontFamily: 'Georgia', fontSize: 33, color: _ink, fontWeight: FontWeight.w700)), const SizedBox(height: 9), const Text('You can change this anytime.', style: TextStyle(color: _muted, fontSize: 14)), const SizedBox(height: 28), _ModeOption(icon: Icons.person_outline_rounded, title: 'Personal', body: 'A private space for your own journey.', value: kModePersonal, selected: selected, onSelect: onSelect), const SizedBox(height: 12), _ModeOption(icon: Icons.groups_outlined, title: 'Family', body: 'Grow gently with the people you love.', value: kModeFamily, selected: selected, onSelect: onSelect), const SizedBox(height: 12), _ModeOption(icon: Icons.auto_awesome_outlined, title: 'Both', body: 'Keep solitude and togetherness close.', value: kModeBoth, selected: selected, onSelect: onSelect)])); }
class _ModeOption extends StatelessWidget { const _ModeOption({required this.icon, required this.title, required this.body, required this.value, required this.selected, required this.onSelect}); final IconData icon; final String title, body; final int value, selected; final ValueChanged<int> onSelect; @override Widget build(BuildContext context) { final active = selected == value; return Material(color: active ? const Color(0xFFF1E2D2) : const Color(0xCCFFFCF8), borderRadius: BorderRadius.circular(20), child: InkWell(onTap: () => onSelect(value), borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? _bronze : const Color(0xFFE8D8C7), width: active ? 1.5 : 1)), child: Row(children: [Icon(icon, color: _bronze), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(body, style: const TextStyle(color: _muted, fontSize: 12))])), Icon(active ? Icons.check_circle_rounded : Icons.circle_outlined, color: active ? _bronze : const Color(0xFFC5B2A0))])))); } }
