import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend_api.dart';

class FamilyJarDetailScreen extends StatefulWidget {
  const FamilyJarDetailScreen({super.key, required this.jarId});

  final int jarId;

  @override
  State<FamilyJarDetailScreen> createState() => _FamilyJarDetailScreenState();
}

class _FamilyJarDetailScreenState extends State<FamilyJarDetailScreen> {
  late Future<_FamilyJarViewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FamilyJarViewData> _load() async {
    final detail = await BackendApi.instance.getFamilyJarDetail(jarId: widget.jarId);
    final leaderboard = await BackendApi.instance.getFamilyLeaderboard(jarId: widget.jarId, limit: 10);
    final topContributor = await BackendApi.instance.getFamilyTopContributor(jarId: widget.jarId);
    return _FamilyJarViewData(detail: detail, leaderboard: leaderboard, topContributor: topContributor);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _leaveJar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave family jar?'),
        content: const Text('You can rejoin later with the invite code. Your contributions remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BackendApi.instance.leaveFamilyJar(jarId: widget.jarId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the family jar.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeMember(int targetUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove user #$targetUserId from this jar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BackendApi.instance.removeFamilyMember(jarId: widget.jarId, targetUserId: targetUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed.')));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied!')));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5D6C3),
        title: Text('Family Jar #${widget.jarId}', style: const TextStyle(color: Color(0xFF3B3327))),
        iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
        elevation: 0,
      ),
      body: FutureBuilder<_FamilyJarViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load family jar data.'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          final detail = data?.detail;
          final leaderboard = data?.leaderboard ?? const <LeaderboardEntry>[];
          final topContributor = data?.topContributor;
          final topContributorMessage = topContributor is Map<String, dynamic>
              ? 'User #${topContributor['user_id'] ?? '—'} with ${topContributor['stars'] ?? 0} stars'
              : topContributor?.toString() ?? 'No contributions yet';

          final members = detail is Map<String, dynamic>
              ? (detail['members'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[]
              : <Map<String, dynamic>>[];
          final currentUserId = detail is Map<String, dynamic> ? detail['current_user_id'] as int? : null;
          final inviteCode = detail is Map<String, dynamic> ? detail['invite_code'] as String? : null;
          final isActive = detail is Map<String, dynamic> ? detail['is_active'] as bool? : true;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: EdgeInsets.all(s(16)),
              children: [
                _JarSummaryCard(
                  scale: scale,
                  jarId: widget.jarId,
                  topContributorMessage: topContributorMessage,
                  inviteCode: inviteCode,
                  isActive: isActive ?? true,
                  onCopyInvite: inviteCode != null ? () => _copyInviteCode(inviteCode) : null,
                ),
                SizedBox(height: s(16)),
                // ── Member roster ──────────────────────────────────────────
                Text(
                  'Members (${members.length})',
                  style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327)),
                ),
                SizedBox(height: s(10)),
                if (members.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: s(24)),
                    child: const Center(child: Text('No members loaded.')),
                  )
                else
                  ...members.map((member) {
                    final userId = member['user_id'] as int? ?? 0;
                    final username = member['username'] as String? ?? 'User #$userId';
                    final role = member['role'] as String? ?? 'member';
                    final contribution = member['contribution'] as Map<String, dynamic>? ?? {};
                    final stars = contribution['stars'] as int? ?? 0;
                    final acts = contribution['acts'] as int? ?? 0;
                    final isCurrentUser = userId == currentUserId;
                    final isAdmin = role == 'admin' || role == 'creator';

                    return Padding(
                      padding: EdgeInsets.only(bottom: s(10)),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3D5C7),
                          borderRadius: BorderRadius.circular(s(12)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: s(16),
                              backgroundColor: const Color(0xFFF5F1EA),
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: TextStyle(color: const Color(0xFF8C6A4A), fontWeight: FontWeight.w700, fontSize: s(12)),
                              ),
                            ),
                            SizedBox(width: s(12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isCurrentUser ? '$username (you)' : username,
                                        style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(15), fontWeight: FontWeight.w600),
                                      ),
                                      if (isAdmin) ...[
                                        SizedBox(width: s(6)),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: s(6), vertical: s(2)),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F3ED),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(role, style: TextStyle(fontSize: s(10), color: const Color(0xFF6A5E52))),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: s(2)),
                                  Text('$stars stars · $acts acts', style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
                                ],
                              ),
                            ),
                            // Remove button — rendered for all but the current user.
                            // The actual authorization check is server-side in the backend.
                            if (!isCurrentUser)
                              IconButton(
                                icon: Icon(Icons.person_remove_outlined, size: s(20), color: Colors.red.shade400),
                                onPressed: () => _removeMember(userId),
                                tooltip: 'Remove member',
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                SizedBox(height: s(16)),
                // ── Leave jar ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: EdgeInsets.symmetric(vertical: s(14)),
                    ),
                    onPressed: _leaveJar,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave this jar'),
                  ),
                ),
                SizedBox(height: s(24)),
                // ── Leaderboard ────────────────────────────────────────────
                Text(
                  'Family Leaderboard',
                  style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327)),
                ),
                SizedBox(height: s(10)),
                if (leaderboard.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: s(24)),
                    child: const Center(child: Text('No family leaderboard entries yet.')),
                  )
                else
                  ...leaderboard.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: s(10)),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3D5C7),
                          borderRadius: BorderRadius.circular(s(12)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: s(16),
                              backgroundColor: const Color(0xFFF5F1EA),
                              child: Text('${index + 1}', style: TextStyle(color: const Color(0xFF8C6A4A), fontWeight: FontWeight.w700, fontSize: s(12))),
                            ),
                            SizedBox(width: s(12)),
                            Expanded(
                              child: Text('User #${row.userId}', style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(15), fontWeight: FontWeight.w600)),
                            ),
                            Text('${row.stars} stars', style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(13))),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FamilyJarViewData {
  _FamilyJarViewData({required this.detail, required this.leaderboard, required this.topContributor});

  final dynamic detail;
  final List<LeaderboardEntry> leaderboard;
  final dynamic topContributor;
}

class _JarSummaryCard extends StatelessWidget {
  const _JarSummaryCard({
    required this.scale,
    required this.jarId,
    required this.topContributorMessage,
    this.inviteCode,
    required this.isActive,
    this.onCopyInvite,
  });

  final double scale;
  final int jarId;
  final String topContributorMessage;
  final String? inviteCode;
  final bool isActive;
  final VoidCallback? onCopyInvite;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFD),
        borderRadius: BorderRadius.circular(s(14)),
        border: Border.all(color: isActive ? const Color(0xFFD3E2C4) : const Color(0xFFE0C0C0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Family jar overview', style: TextStyle(color: const Color(0xFF1C1A19), fontSize: s(18), fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(3)),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFD3E2C4) : const Color(0xFFE0C0C0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(isActive ? 'Active' : 'Completed', style: TextStyle(fontSize: s(11), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: s(6)),
          Text('Jar ID: $jarId', style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(13))),
          if (inviteCode != null) ...[
            SizedBox(height: s(8)),
            Row(
              children: [
                Text('Invite code: ', style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(13))),
                Text(inviteCode!, style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(14), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                SizedBox(width: s(8)),
                if (onCopyInvite != null)
                  GestureDetector(
                    onTap: onCopyInvite,
                    child: Icon(Icons.copy, size: s(16), color: const Color(0xFF8C6A4A)),
                  ),
              ],
            ),
          ],
          SizedBox(height: s(10)),
          Text('Top contributor', style: TextStyle(color: const Color(0xFF7A5B3E), fontSize: s(12), fontWeight: FontWeight.w600)),
          SizedBox(height: s(4)),
          Text(topContributorMessage, style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(15), height: 1.35)),
        ],
      ),
    );
  }
}