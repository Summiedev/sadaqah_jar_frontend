import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/backend_api.dart';
import 'family_models.dart';
import 'family_theme.dart';

class PrayerRequestsScreen extends StatefulWidget {
  const PrayerRequestsScreen({required this.id, super.key});

  final String id;

  @override
  State<PrayerRequestsScreen> createState() => _PrayerRequestsScreenState();
}

class _PRequest {
  const _PRequest(this.author, this.accent, this.text, this.time, {this.id, this.ameen = 0, this.ease = 0, this.accept = 0});
  final String? id;
  final String author;
  final Color accent;
  final String text;
  final String time;
  final int ameen;
  final int ease;
  final int accept;

  _PRequest copyWith({String? id, String? author, Color? accent, String? text, String? time, int? ameen, int? ease, int? accept}) {
    return _PRequest(
      author ?? this.author,
      accent ?? this.accent,
      text ?? this.text,
      time ?? this.time,
      id: id ?? this.id,
      ameen: ameen ?? this.ameen,
      ease: ease ?? this.ease,
      accept: accept ?? this.accept,
    );
  }
}

class _PrayerRequestsScreenState extends State<PrayerRequestsScreen> {
  FamilyJar? _jar;
  final List<_PRequest> _requests = [];
  final TextEditingController _c = TextEditingController();
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _jar = getFamilyById(widget.id);
    _loadPrayers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _c.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadPrayers();
      }
    });
  }

  Future<void> _loadPrayers() async {
    setState(() { _loading = true; _error = null; });
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      _loadMock();
      return;
    }
    try {
      final prayers = await BackendApi.instance.getFamilyPrayers(familyId);
      if (!mounted) return;
      setState(() {
        _requests.clear();
        _requests.addAll(prayers.map((p) {
          final counts = p['response_counts'] != null ? Map<String, int>.from(p['response_counts'] as Map) : const <String, int>{};
          return _PRequest(
            'You',
            fBronze,
            p['text']?.toString() ?? '',
            'just now',
            id: p['id']?.toString(),
            ameen: counts['ameen'] ?? 0,
            ease: counts['grant_ease'] ?? 0,
            accept: counts['accept'] ?? 0,
          );
        }));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _loadMock();
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _loadMock() {
    _requests.addAll([
      _PRequest('A family member', fOlive, 'Please remember my exams in your du\'a.', '1h'),
      _PRequest('A family member', fBronze, 'Please pray for my dad. He is not feeling well, and I would really appreciate your du\'a.', '4h'),
      _PRequest('A family member', fBronzeDark, 'Please remember our family this Friday.', 'Yesterday'),
    ]);
  }

  Future<void> _add() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final familyId = int.tryParse(widget.id);
    if (familyId == null) {
      setState(() {
        _requests.insert(0, _PRequest('You', fBronze, text, 'now'));
        _c.clear();
      });
      return;
    }
    try {
      final result = await BackendApi.instance.createFamilyPrayer(familyId, text: text);
      if (!mounted) return;
      setState(() {
        _requests.insert(0, _PRequest('You', fBronze, text, 'just now', id: result['id']?.toString()));
        _c.clear();
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.brown));
    }
  }

  Future<void> _respond(int index, String type) async {
    final request = _requests[index];
    final familyId = int.tryParse(widget.id);
    final prayerId = int.tryParse(request.id ?? '');
    if (familyId == null || prayerId == null) {
      setState(() {
        final current = _requests[index];
        final newAmeen = type == 'ameen' ? current.ameen + 1 : current.ameen;
        final newEase = type == 'grant_ease' ? current.ease + 1 : current.ease;
        final newAccept = type == 'accept' ? current.accept + 1 : current.accept;
        _requests[index] = current.copyWith(ameen: newAmeen, ease: newEase, accept: newAccept);
      });
      return;
    }
    try {
      final result = await BackendApi.instance.respondToFamilyPrayer(familyId, prayerId, type);
      if (!mounted) return;
      final counts = result['response_counts'] != null
        ? Map<String, int>.from(result['response_counts'] as Map)
        : <String, int>{};
      setState(() {
        _requests[index] = _requests[index].copyWith(
          ameen: counts['ameen'] ?? _requests[index].ameen,
          ease: counts['grant_ease'] ?? _requests[index].ease,
          accept: counts['accept'] ?? _requests[index].accept,
        );
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.brown));
    }
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
                title: 'Prayer Requests',
                subtitle: jar == null ? null : 'Hold one another in du\'a',
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
            _PComposeBar(controller: _c, onSend: _add),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _requests.isEmpty) {
      return const Center(child: SizedBox(height: 80, child: DecoratedBox(decoration: BoxDecoration(color: fClayLight, borderRadius: BorderRadius.all(Radius.circular(20))))));
    }
    if (_error != null && _requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: fBronze),
            const SizedBox(height: 18),
            const Text('Could not load prayer requests', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
            const SizedBox(height: 18),
            FilledButton(onPressed: _loadPrayers, child: const Text('Retry')),
          ]),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const _EmptyPrayers();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _RequestCard(key: ValueKey(index), r: _requests[index], onRespond: (type) => _respond(index, type)),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.r, required this.onRespond, super.key});

  final _PRequest r;
  final ValueChanged<String> onRespond;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return SoftCard(
      color: fClayPale,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MizanAvatar(name: r.author, accent: r.accent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fWalnut)),
                    Text(r.time, style: const TextStyle(fontSize: 10.5, color: fStoneLight)),
                  ],
                ),
              ),
              const Icon(Icons.favorite_border_outlined, size: 16, color: fBronze),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.text, style: const TextStyle(fontSize: 14, height: 1.5, color: fWalnut)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResponseChip(label: 'Ameen', active: r.ameen > 0, count: r.ameen, onTap: () => widget.onRespond('ameen')),
              _ResponseChip(label: 'May Allah grant ease', active: r.ease > 0, count: r.ease, onTap: () => widget.onRespond('grant_ease')),
              _ResponseChip(label: 'May Allah accept', active: r.accept > 0, count: r.accept, onTap: () => widget.onRespond('accept')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseChip extends StatefulWidget {
  const _ResponseChip({required this.label, required this.active, required this.count, required this.onTap});

  final String label;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  State<_ResponseChip> createState() => _ResponseChipState();
}

class _ResponseChipState extends State<_ResponseChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  late final Animation<double> _a = Tween<double>(begin: 1, end: 0.92).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  bool _tapped = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active || _tapped;
    return Semantics(
      button: true,
      label: '${widget.label}, ${widget.count} responses',
      child: ScaleTransition(
        scale: _a,
        child: Material(
          color: active ? fBronze.withValues(alpha: 0.12) : fWhite,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTapDown: (_) => _c.forward(),
            onTapUp: (_) => _c.reverse(),
            onTapCancel: () => _c.reverse(),
            onTap: () {
              setState(() => _tapped = true);
              widget.onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: active ? fBronze : fClay)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? fBronze : fStone)),
                  if (active) const SizedBox(width: 6),
                  if (active) const Icon(Icons.check, size: 12, color: fBronze),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PComposeBar extends StatelessWidget {
  const _PComposeBar({required this.controller, required this.onSend});

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
                  hintText: 'Request a private du\'a…',
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

class _EmptyPrayers extends StatelessWidget {
  const _EmptyPrayers();

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
            child: const Center(child: Icon(Icons.favorite_border_outlined, size: 38, color: fBronze)),
          ),
          const SizedBox(height: 18),
          const Text('No prayer requests', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('Support one another through du\'a. Share a request and let your family hold you close.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
        ],
      ),
    );
  }
}
