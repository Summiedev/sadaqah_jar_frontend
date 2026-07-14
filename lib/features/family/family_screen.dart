import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'family_models.dart';
import 'family_theme.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 650));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _HubSkeleton();
            }
            final jars = allFamilies();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _HubHeader()),
                if (jars.isEmpty)
                  const SliverFillRemaining(child: _EmptyFamily())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final jar = jars[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _JarCard(jar: jar),
                          );
                        },
                        childCount: jars.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: _HubActions()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Family', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(999), border: Border.all(color: fClay)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_outline, size: 13, color: fBronze),
                    SizedBox(width: 6),
                    Text('Growing together', style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: fBronzeDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A quiet space where loved ones encourage one another through small, consistent goodness.',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone),
          ),
        ],
      ),
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({required this.jar});

  final FamilyJar jar;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => context.push('/family/jar/${jar.id}'),
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
                child: Center(child: Text(jar.coverEmoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jar.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 13, color: fStoneLight),
                        const SizedBox(width: 5),
                        Text('${jar.memberCount} members', style: const TextStyle(fontSize: 11, color: fStoneLight)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_outlined, size: 13, color: fStoneLight),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(jar.lastActivity, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: fStoneLight)),
                        ),
                      ],
                    ),
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
                child: Text('${jar.goalLabel} · ${(jar.progress * 100).round()}%', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fBronzeDark)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text('${jar.daysRemaining} days left', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: fStoneLight)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressTrack(value: jar.progress),
        ],
      ),
    );
  }
}

class _HubActions extends StatelessWidget {
  const _HubActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          MizanButton(label: 'Create Family Jar', onTap: () => _showComingSoon(context, 'Create Family Jar')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MizanOutlineButton(
                  label: 'Join Existing Jar',
                  onTap: () => context.push('/family/invitations'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MizanOutlineButton(
                  label: 'View Invitations',
                  onTap: () => context.push('/family/invitations'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily();

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
          const Text('No Family Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text(
            'Create your first Family Jar and grow in goodness together — quietly, consistently.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone),
          ),
          const SizedBox(height: 18),
          MizanButton(label: 'Create your first Family Jar', onTap: () {}),
        ],
      ),
    );
  }
}

class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) {
    final block = Container(
      height: 132,
      decoration: BoxDecoration(color: fPaper, borderRadius: BorderRadius.circular(24), border: Border.all(color: fClay)),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Container(width: 120, height: 22, decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 14),
        block,
        const SizedBox(height: 14),
        block,
        const SizedBox(height: 14),
        block,
      ],
    );
  }
}

void _showComingSoon(BuildContext context, String title) {
  showModalBottomSheet(
    context: context,
    backgroundColor: fIvory,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: fClay, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('This gentle flow is being crafted with care. You are in the Family section preview.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
          const SizedBox(height: 20),
          MizanButton(label: 'Close', onTap: () => context.pop()),
        ],
      ),
    ),
  );
}
