import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backend_api.dart';
import '../../core/mode_provider.dart';
import 'family_models.dart';
import 'family_theme.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  late List<String> _pending;
  List<Map<String, dynamic>> _families = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pending = [...pendingRequests];
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final families = await BackendApi.instance.getFamilies();
      if (!mounted) return;
      setState(() {
        _families = families;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Create a family jar', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start a shared space for your family.', style: TextStyle(color: fStone, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Family name',
                hintText: 'e.g. The Ahmad Family',
                filled: true,
                fillColor: fPaper,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fClay)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: fStone))),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, name);
            },
            style: FilledButton.styleFrom(backgroundColor: fBronze),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    try {
      final response = await BackendApi.instance.createFamilyJar(name: result);
      if (!mounted) return;
      final inviteCode = response['invite_code'] as String? ?? '';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: fIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Family jar created!', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code with your family members:', style: TextStyle(color: fStone, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: fPaper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: fClay),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inviteCode,
                        style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w800, color: fWalnut, letterSpacing: 1.5),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const Text('Invite code copied!')));
                      },
                      icon: const Icon(Icons.copy_rounded, color: fBronze),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: fBronze),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      _loadFamilies();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: Text('Could not create jar: $e')));
    }
  }

  Future<void> _joinFamily() async {
    final codeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Join a family jar', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the invite code shared with you.', style: TextStyle(color: fStone, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Invite code',
                hintText: 'e.g. MIZAN-ABC-123',
                filled: true,
                fillColor: fPaper,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fClay)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: fStone))),
          FilledButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx, code);
            },
            style: FilledButton.styleFrom(backgroundColor: fBronze),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    try {
      await BackendApi.instance.joinFamilyJar(inviteCode: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const Text('Joined family jar!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: Text('Could not join jar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final offset = notification.metrics.pixels;
            if (offset > 10) {
              if (!ref.read(isScrolledProvider.notifier).state) {
                ref.read(isScrolledProvider.notifier).state = true;
              }
            } else if (offset <= 0) {
              if (ref.read(isScrolledProvider.notifier).state) {
                ref.read(isScrolledProvider.notifier).state = false;
              }
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              toolbarHeight: 64,
              collapsedHeight: 64,
              expandedHeight: 64,
              backgroundColor: const Color(0xFFE8DCC8),
              foregroundColor: fWalnutLight,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text('Family'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: () => context.push('/family/invitations'),
                    tooltip: 'Invitations',
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8C99B)),
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.person_add_outlined, size: 18, color: Color(0xFF9E7B5A))),
                          if (_pending.isNotEmpty)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB6544D),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Center(
                                  child: Text('${_pending.length}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: fBronze)))
            else if (_error != null)
              SliverFillRemaining(child: _ErrorState(message: _error!, onRetry: _loadFamilies))
            else if (_families.isEmpty)
              SliverFillRemaining(child: _EmptyFamily(onJoin: _joinFamily, onCreate: _createFamily))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final jar = _families[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _JarCard(jar: jar),
                      );
                    },
                    childCount: _families.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: const Color(0xFFFFF0EE), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF0BCB5))),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: Color(0xFFB85450)),
            ),
            const SizedBox(height: 20),
            Text('Could not load families', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF2F241E), fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6D5B4D), fontSize: 13, height: 1.5)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B6842), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({required this.jar});

  final Map<String, dynamic> jar;

  @override
  Widget build(BuildContext context) {
    final name = jar['name']?.toString() ?? 'Family';
    final memberCount = (jar['member_count'] as num?)?.toInt() ?? 0;
    final progress = (jar['progress'] as num?)?.toDouble() ?? 0.0;
    final daysRemaining = (jar['days_remaining'] as num?)?.toInt() ?? 0;
    final goalLabel = jar['goal_label']?.toString() ?? '';
    return Semantics(
      button: true,
      label: 'Open $name, $memberCount members, ${(progress * 100).round()} percent complete',
      child: SoftCard(
        onTap: () => context.push('/family/jar/${jar['id']}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(18), border: Border.all(color: fClay)),
                  child: const Center(child: Icon(Icons.favorite_border_rounded, size: 28, color: fBronze)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                      const SizedBox(height: 4),
                      Text('$memberCount members', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: fStoneLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('$goalLabel · ${(progress * 100).round()}%', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fBronzeDark)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text('$daysRemaining days left', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: fStoneLight)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressTrack(value: progress),
          ],
        ),
      ),
    );
  }
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily({required this.onJoin, required this.onCreate});

  final VoidCallback onJoin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
            child: const Center(child: Icon(Icons.groups_outlined, size: 40, color: fBronze)),
          ),
          const SizedBox(height: 20),
          const Text('No family yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text(
            'Create a jar or join one with an invite code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Join with code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fWalnut,
                    side: BorderSide(color: fClay),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MizanButton(label: 'Create a jar', onTap: onCreate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
