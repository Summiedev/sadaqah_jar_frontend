import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/backend_api.dart';
import 'family_models.dart';
import 'family_theme.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({this.id, super.key});

  final String? id;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final List<String> _pending = [...pendingRequests];
  FamilyJar? _selectedJar;
  String? _createdRoomName;
  String? _createdInviteCode;
  bool _creatingRoom = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    final jar = widget.id != null ? getFamilyById(widget.id!) : null;
    if (jar != null) _selectedJar = jar;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fIvory,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ScreenHeader(title: 'Invitations', subtitle: 'Grow your circle, gently'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(16), border: Border.all(color: fClay)),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: fWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: fClay)),
                  labelColor: fWalnut,
                  unselectedLabelColor: fStoneLight,
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Invite'), Tab(text: 'Pending')],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _InvitePanel(
                    selectedJar: _selectedJar,
                    createdRoomName: _createdRoomName,
                    createdInviteCode: _createdInviteCode,
                    creatingRoom: _creatingRoom,
                    onSelectJar: (jar) => setState(() => _selectedJar = jar),
                    onCreateRoom: _createRoom,
                  ),
                  _PendingPanel(pending: _pending, onRemove: (i) => setState(() => _pending.removeAt(i))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Create a room', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: fWalnut)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start the room first. Then you can share its invite code and QR.', style: TextStyle(color: fStone, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Room name',
                hintText: 'e.g. The Ahmad Family',
                filled: true,
                fillColor: fPaper,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fClay)),
              ),
              onSubmitted: (_) {
                final value = nameController.text.trim();
                if (value.isNotEmpty) Navigator.pop(ctx, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: fStone))),
          FilledButton(
            onPressed: () {
              final value = nameController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(ctx, value);
            },
            style: FilledButton.styleFrom(backgroundColor: fBronze),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || !mounted) return;
    setState(() => _creatingRoom = true);
    try {
      final response = await BackendApi.instance.createFamilyJar(name: name);
      if (!mounted) return;
      final inviteCode = response['invite_code'] as String? ?? '';
      setState(() {
        _createdRoomName = name;
        _createdInviteCode = inviteCode.isEmpty ? _fallbackInviteCode(name) : inviteCode;
        _selectedJar = null;
        _creatingRoom = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _createdRoomName = name;
        _createdInviteCode = _fallbackInviteCode(name);
        _selectedJar = null;
        _creatingRoom = false;
      });
    }
  }

  String _fallbackInviteCode(String name) {
    final slug = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.remainder(1000).toString().padLeft(3, '0');
    return 'MIZAN-${slug.isEmpty ? 'ROOM' : slug}-$suffix';
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({
    required this.selectedJar,
    required this.createdRoomName,
    required this.createdInviteCode,
    required this.creatingRoom,
    required this.onSelectJar,
    required this.onCreateRoom,
  });

  final FamilyJar? selectedJar;
  final String? createdRoomName;
  final String? createdInviteCode;
  final bool creatingRoom;
  final ValueChanged<FamilyJar> onSelectJar;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    final roomName = createdRoomName ?? selectedJar?.name;
    final code = createdInviteCode ?? selectedJar?.inviteCode;
    if (code == null || roomName == null) {
      return _InviteSetupPanel(
        creatingRoom: creatingRoom,
        onSelectJar: onSelectJar,
        onCreateRoom: onCreateRoom,
      );
    }
    final link = 'https://mizan.app/join?code=$code';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _RoomSummary(name: roomName, onCreateRoom: onCreateRoom),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            children: [
              const Text('Scan to join this room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
              const SizedBox(height: 4),
              const Text('A quiet doorway into the family jar.', style: TextStyle(fontSize: 11.5, color: fStone)),
              const SizedBox(height: 16),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(color: fWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: fClay)),
                padding: const EdgeInsets.all(14),
                child: CustomPaint(painter: _QrPainter(seed: code)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: fClay)),
                child: Row(
                  children: [
                    Expanded(child: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1, color: fWalnut))),
                    IconButton(visualDensity: VisualDensity.compact, tooltip: 'Copy invite code', onPressed: () => _copy(context, code), icon: const Icon(Icons.copy_outlined, size: 16, color: fBronze)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionLabel('Share another way'),
        const SizedBox(height: 10),
        _InviteOption(icon: Icons.link_outlined, label: 'Copy invite link', subtitle: link, onTap: () => _copy(context, link)),
        const SizedBox(height: 10),
        _InviteOption(icon: Icons.chat_outlined, label: 'WhatsApp', subtitle: 'Send a gentle message', onTap: () => _launch(context, Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Join my family jar on Mizan: $link')}'))),
        const SizedBox(height: 10),
        _InviteOption(icon: Icons.mail_outline, label: 'Email', subtitle: 'Invite by email', onTap: () => _launch(context, Uri(scheme: 'mailto', queryParameters: {'subject': 'Join my family jar on Mizan', 'body': 'Join my family jar on Mizan: $link'}))),
      ],
    );
  }
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating));
}

Future<void> _launch(BuildContext context, Uri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No app is available to share this invitation.'), behavior: SnackBarBehavior.floating));
  }
}

class _InviteSetupPanel extends StatelessWidget {
  const _InviteSetupPanel({required this.creatingRoom, required this.onSelectJar, required this.onCreateRoom});

  final bool creatingRoom;
  final ValueChanged<FamilyJar> onSelectJar;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    final jars = allFamilies();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: fBronze.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.meeting_room_outlined, color: fBronze),
              ),
              const SizedBox(height: 14),
              const Text('Create or choose a room first', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
              const SizedBox(height: 8),
              const Text('Invite links and QR codes belong to one room, so pick the room before sharing.', style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
              const SizedBox(height: 16),
              MizanButton(
                label: creatingRoom ? 'Creating...' : 'Create room',
                onTap: creatingRoom ? () {} : onCreateRoom,
              ),
            ],
          ),
        ),
        if (jars.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionLabel('Or choose an existing room'),
          const SizedBox(height: 10),
          for (final jar in jars) ...[
            _RoomOption(jar: jar, onTap: () => onSelectJar(jar)),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _RoomSummary extends StatelessWidget {
  const _RoomSummary({required this.name, required this.onCreateRoom});

  final String name;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fClayPale,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: fClay)),
        child: Row(
          children: [
            const Icon(Icons.meeting_room_outlined, color: fBronze, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
            ),
            TextButton.icon(
              onPressed: onCreateRoom,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New'),
              style: TextButton.styleFrom(foregroundColor: fBronze, visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({required this.jar, required this.onTap});

  final FamilyJar jar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fPaper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: fClay)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: fClayPale, borderRadius: BorderRadius.circular(14)),
                child: Icon(jar.coverIcon, color: fBronze, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jar.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
                    const SizedBox(height: 2),
                    Text('${jar.memberCount} members', style: const TextStyle(fontSize: 11, color: fStoneLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: fBronze, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteOption extends StatelessWidget {
  const _InviteOption({required this.icon, required this.label, required this.subtitle, required this.onTap});

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fPaper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: fClay)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: fBronze.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 20, color: fBronze),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
                    const SizedBox(height: 2),
                    Text(subtitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: fStoneLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: fBronze),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel({required this.pending, required this.onRemove});

  final List<String> pending;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: fClayPale, shape: BoxShape.circle, border: Border.all(color: fClay)),
              child: const Center(child: Icon(Icons.mark_email_read_outlined, size: 36, color: fBronze)),
            ),
            const SizedBox(height: 18),
            const Text('No pending requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            const Text('When someone asks to join, their request will appear here for you to welcome.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final parts = pending[index].split(' — ');
        final name = parts.first;
        final by = parts.length > 1 ? parts.last : '';
        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MizanAvatar(name: name, accent: fBronze, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fWalnut)),
                        if (by.isNotEmpty)
                          Text(by, style: const TextStyle(fontSize: 11, color: fStoneLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MizanButton(
                      label: 'Welcome',
                      onTap: () => onRemove(index),
                      fullWidth: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MizanOutlineButton(
                      label: 'Decline',
                      onTap: () => onRemove(index),
                      fullWidth: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Decorative, dependency-free QR-style square (prototype placeholder).
class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed});
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed.hashCode);
    final cells = 11;
    final cell = size.width / cells;
    final paint = Paint()..color = fWalnut;
    for (int y = 0; y < cells; y++) {
      for (int x = 0; x < cells; x++) {
        if (rng.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    // Finder squares
    _drawFinder(canvas, paint, 0, 0, cell);
    _drawFinder(canvas, paint, size.width - cell * 3, 0, cell);
    _drawFinder(canvas, paint, 0, size.height - cell * 3, cell);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

void _drawFinder(Canvas canvas, Paint paint, double fx, double fy, double cell) {
  canvas.drawRect(Rect.fromLTWH(fx, fy, cell * 3, cell * 3), paint);
  canvas.drawRect(Rect.fromLTWH(fx + cell * 0.6, fy + cell * 0.6, cell * 1.8, cell * 1.8), Paint()..color = fWhite);
  canvas.drawRect(Rect.fromLTWH(fx + cell, fy + cell, cell, cell), paint);
}
