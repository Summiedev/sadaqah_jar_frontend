import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/backend_api.dart';
import 'family_theme.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({this.id, super.key});

  final String? id;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _families = const [];
  Map<String, dynamic>? _selectedJar;

  String? _createdRoomName;
  String? _createdInviteCode;
  bool _creatingRoom = false;
  bool _loadingRooms = true;
  String? _roomsError;
  bool _loadingPending = true;
  String? _pendingError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadRooms();
    _loadPending();
  }

  Future<void> _loadPending() async {
    if (!mounted) return;
    setState(() { _loadingPending = true; _pendingError = null; });
    try {
      final pending = await BackendApi.instance.getPendingInvitations();
      if (!mounted) return;
      setState(() { _pending..clear()..addAll(pending); _loadingPending = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _pendingError = error.toString(); _loadingPending = false; });
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final families = await BackendApi.instance.getFamilies();
      if (!mounted) return;
      setState(() {
        _families = families;
        _selectedJar = _findSelectedRoom(families);
        _loadingRooms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roomsError = e.toString();
        _loadingRooms = false;
      });
    }
  }

  Map<String, dynamic>? _findSelectedRoom(List<Map<String, dynamic>> families) {
    if (widget.id == null) return null;
    for (final family in families) {
      if (family['id']?.toString() == widget.id) return family;
    }
    return null;
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
                  tabs: const [Tab(text: 'Invite'), Tab(text: 'Active invites')],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _InvitePanel(
                    families: _families,
                    selectedJar: _selectedJar,
                    createdRoomName: _createdRoomName,
                    createdInviteCode: _createdInviteCode,
                    creatingRoom: _creatingRoom,
                    loadingRooms: _loadingRooms,
                    roomsError: _roomsError,
                    onReloadRooms: _loadRooms,
                    onSelectJar: (jar) => setState(() => _selectedJar = jar),
                    onCreateRoom: _createRoom,
                  ),
                  _PendingPanel(
                    pending: _pending,
                    loading: _loadingPending,
                    error: _pendingError,
                    onRetry: _loadPending,
                    onCancel: _cancelPending,
                  ),
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
        _createdInviteCode = inviteCode;
        _selectedJar = null;
        _creatingRoom = false;
      });
      _loadRooms();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingRoom = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create room: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelPending(Map<String, dynamic> invitation) async {
    final familyId = (invitation['family_id'] as num?)?.toInt();
    final invitationId = (invitation['id'] as num?)?.toInt();
    if (familyId == null || invitationId == null) return;
    try {
      await BackendApi.instance.cancelFamilyInvitation(
        familyId: familyId,
        invitationId: invitationId,
      );
      if (!mounted) return;
      setState(() => _pending.removeWhere((item) => item['id'] == invitationId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation cancelled')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel invitation: $error')));
    }
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({
    required this.families,
    required this.selectedJar,
    required this.createdRoomName,
    required this.createdInviteCode,
    required this.creatingRoom,
    required this.loadingRooms,
    required this.roomsError,
    required this.onReloadRooms,
    required this.onSelectJar,
    required this.onCreateRoom,
  });

  final List<Map<String, dynamic>> families;
  final Map<String, dynamic>? selectedJar;
  final String? createdRoomName;
  final String? createdInviteCode;
  final bool creatingRoom;
  final bool loadingRooms;
  final String? roomsError;
  final VoidCallback onReloadRooms;
  final ValueChanged<Map<String, dynamic>> onSelectJar;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    final roomName = createdRoomName ?? selectedJar?['name']?.toString();
    final code = createdInviteCode ?? selectedJar?['invite_code']?.toString();
    if (code == null || roomName == null) {
      return _InviteSetupPanel(
        families: families,
        creatingRoom: creatingRoom,
        loadingRooms: loadingRooms,
        roomsError: roomsError,
        onReloadRooms: onReloadRooms,
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
                 child: QrImageView(
                   data: link,
                   version: QrVersions.auto,
                   size: 152,
                   backgroundColor: fWhite,
                   errorCorrectionLevel: QrErrorCorrectLevel.M,
                 ),
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
  const _InviteSetupPanel({
    required this.families,
    required this.creatingRoom,
    required this.loadingRooms,
    required this.roomsError,
    required this.onReloadRooms,
    required this.onSelectJar,
    required this.onCreateRoom,
  });

  final List<Map<String, dynamic>> families;
  final bool creatingRoom;
  final bool loadingRooms;
  final String? roomsError;
  final VoidCallback onReloadRooms;
  final ValueChanged<Map<String, dynamic>> onSelectJar;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (loadingRooms)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(color: fBronze)),
          )
        else if (roomsError != null)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Could not load rooms', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fWalnut)),
                const SizedBox(height: 6),
                Text(roomsError!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: fStone)),
                const SizedBox(height: 12),
                MizanOutlineButton(label: 'Try again', onTap: onReloadRooms),
              ],
            ),
          )
        else if (families.isNotEmpty) ...[
          const SectionLabel('Your rooms'),
          const SizedBox(height: 10),
          for (final jar in families) ...[
            _RoomOption(jar: jar, onTap: () => onSelectJar(jar)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
        ],
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
              const Text('Create a new room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
              const SizedBox(height: 8),
              const Text('Start a new family jar and share its invite code and QR.', style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
              const SizedBox(height: 16),
              MizanButton(
                label: creatingRoom ? 'Creating...' : 'Create room',
                onTap: creatingRoom ? () {} : onCreateRoom,
              ),
            ],
          ),
        ),
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

  final Map<String, dynamic> jar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = jar['name']?.toString() ?? 'Family jar';
    final memberCount = (jar['member_count'] as num?)?.toInt() ?? 0;
    return Semantics(
      button: true,
      label: 'Use $name, $memberCount members',
      child: Material(
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
                  child: const Icon(Icons.favorite_border_rounded, color: fBronze, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fWalnut)),
                      const SizedBox(height: 2),
                      Text('$memberCount members', style: const TextStyle(fontSize: 11, color: fStoneLight)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: fBronze, size: 20),
              ],
            ),
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
    return Semantics(
      button: true,
      label: label,
      child: Material(
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
      ),
    );
  }
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel({required this.pending, required this.loading, required this.error, required this.onRetry, required this.onCancel});

  final List<Map<String, dynamic>> pending;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Map<String, dynamic>> onCancel;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: fBronze));
    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 42, color: fBronze),
        const SizedBox(height: 12),
        const Text('Could not load pending invitations', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: fWalnut)),
        const SizedBox(height: 12),
        MizanOutlineButton(label: 'Try again', onTap: onRetry),
      ])));
    }
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
            const Text('No active invites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fWalnut, fontFamily: 'Georgia')),
            const SizedBox(height: 8),
            const Text('Invites you create remain here until they expire or you cancel them.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: fStone)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invitation = pending[index];
        final name = invitation['family_name']?.toString() ?? 'Family jar';
        final code = invitation['invite_code']?.toString() ?? '';
        final expires = invitation['expires_at']?.toString() ?? '';
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
                        Text('Invite code: $code', style: const TextStyle(fontSize: 11, color: fStoneLight)),
                        if (expires.isNotEmpty)
                          Text('Expires ${_shortDate(expires)}', style: const TextStyle(fontSize: 11, color: fStoneLight)),
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
                    label: 'Cancel invite',
                      onTap: () => onCancel(invitation),
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

  String _shortDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day}/${date.month}/${date.year}';
  }
}
