import 'package:flutter/material.dart';

import 'family_models.dart';
import 'family_theme.dart';

class FamilyReflectionsScreen extends StatefulWidget {
  const FamilyReflectionsScreen({required this.id, super.key});

  final String id;

  @override
  State<FamilyReflectionsScreen> createState() => _FamilyReflectionsScreenState();
}

class _FReflection {
  _FReflection(this.author, this.authorAccent, this.text, this.time);
  final String author;
  final Color authorAccent;
  final String text;
  final String time;
  final Map<String, int> encouragement = <String, int>{
    'May Allah accept': 0,
    'Ameen': 0,
    'Barakallahu feek': 0,
    'May Allah increase you': 0,
  };
}

class _FamilyReflectionsScreenState extends State<FamilyReflectionsScreen> {
  late final Future<void> _load = Future<void>.delayed(const Duration(milliseconds: 500));
  FamilyJar? _jar;
  final List<_FReflection> _reflections = [];
  final TextEditingController _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _reflections.addAll([
      _FReflection('Fatimah Ahmad', fOlive, 'Alhamdulillah for another week together.', '2h'),
      _FReflection('Yusuf Ahmad', fBronze, 'May Allah accept our efforts this month.', '5h'),
      _FReflection('Maryam Ahmad', fBronzeDark, 'Grateful we could help someone today.', 'Yesterday'),
      _FReflection('Hafsa Ahmad', fOlive, 'Small things, done with love, are never small.', 'Yesterday'),
    ]);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _reflections.insert(0, _FReflection('You', fBronze, t, 'now'));
      _c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jar = _jar;
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ScreenHeader(
                title: 'Reflections',
                subtitle: jar == null ? null : 'A quiet journal for ${jar.name}',
              ),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _load,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: SizedBox(height: 80, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20))))));
                  }
                  if (_reflections.isEmpty) {
                    return const _EmptyReflections();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: _reflections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReflectionCard(
                      r: _reflections[index],
                      onPick: (k) => setState(() => _reflections[index].encouragement[k] = (_reflections[index].encouragement[k] ?? 0) + 1),
                    ),
                  );
                },
              ),
            ),
            _FComposeBar(controller: _c, onSend: _add),
          ],
        ),
      ),
    );
  }
}

const List<String> _encourageOptions = <String>['May Allah accept', 'Ameen', 'Barakallahu feek', 'May Allah increase you'];

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.r, required this.onPick});

  final _FReflection r;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.authorAccent, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
                    Text(r.time, style: const TextStyle(fontSize: 10.5, color: fStoneLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('“${r.text}”', style: const TextStyle(fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic, color: fWalnut)),
          const SizedBox(height: 14),
          const Divider(height: 1, color: fClayLight),
          const SizedBox(height: 12),
          const Text('Offer gentle encouragement', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: fStonePale)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _encourageOptions.map((k) {
              final count = r.encouragement[k] ?? 0;
              return Material(
                color: count > 0 ? r.authorAccent.withValues(alpha: 0.12) : fWhite,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onPick(k),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: count > 0 ? r.authorAccent : fClay),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(k, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: count > 0 ? r.authorAccent : fStone)),
                        ),
                        if (count > 0) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: r.authorAccent, borderRadius: BorderRadius.circular(999)),
                            child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fWhite)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FComposeBar extends StatelessWidget {
  const _FComposeBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(color: fSurface, border: Border(top: BorderSide(color: fClay))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: fWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: fClay)),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 13.5, height: 1.45, color: fWalnut),
                decoration: const InputDecoration(
                  hintText: 'Share a quiet reflection…',
                  hintStyle: TextStyle(color: fStonePale, fontStyle: FontStyle.italic),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: fBronze,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSend,
              child: const SizedBox(width: 46, height: 46, child: Icon(Icons.send_outlined, size: 18, color: fWhite)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReflections extends StatelessWidget {
  const _EmptyReflections();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
            child: const Center(child: Icon(Icons.menu_book_outlined, size: 38, color: fBronze)),
          ),
          const SizedBox(height: 18),
          const Text('No reflections yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('Share your first reflection with your family. No replies — only quiet encouragement.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        ],
      ),
    );
  }
}
