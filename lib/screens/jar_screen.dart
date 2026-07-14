import 'dart:math';

import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../widgets/live_jar_panel.dart';
import '../widgets/notification_action_button.dart';
import 'acts_library_screen.dart';
import 'archived_jars_screen.dart';
import 'family_jar_detail_screen.dart';

String _generateRequestId() {
  final random = Random();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');

  final hex = bytes.map(hexByte).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

class JarScreen extends StatefulWidget {
  const JarScreen({super.key});

  @override
  State<JarScreen> createState() => _JarScreenState();
}

class _JarScreenState extends State<JarScreen> {
  final Set<int> _pendingActIds = {};

  Future<void> _showCreateFamilyJar(BuildContext context) async {
    final nameController = TextEditingController(text: 'Family Jar');
    final capacityController = TextEditingController(text: '33');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return _BottomSheetCard(
          title: 'Create family jar',
          subtitle: 'Set a name and capacity, then invite people into a shared progress loop.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetField(controller: nameController, label: 'Jar name', hint: 'Family Jar'),
              const SizedBox(height: 12),
              _SheetField(controller: capacityController, label: 'Capacity', hint: '33', keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              const _SheetHintRow(hints: ['Invite code', 'Shared leaderboard', 'Live updates']),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;
    try {
      final response = await BackendApi.instance.createFamilyJar(
        name: nameController.text.trim(),
        capacity: int.tryParse(capacityController.text) ?? 33,
      );
      if (context.mounted) {
        final jarId = (response['jar_id'] as num?)?.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family jar created: ${response['invite_code'] ?? 'invite ready'}')),
        );
        if (jarId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: jarId)));
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _showJoinFamilyJar(BuildContext context) async {
    final codeController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return _BottomSheetCard(
          title: 'Join family jar',
          subtitle: 'Enter an invite code to join the live family board.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetField(controller: codeController, label: 'Invite code', hint: 'SHARED-1234'),
              const SizedBox(height: 14),
              const _SheetHintRow(hints: ['Family progress', 'Streaks', 'Shared wins']),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Join')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;
    try {
      final response = await BackendApi.instance.joinFamilyJar(inviteCode: codeController.text.trim());
      if (context.mounted) {
        final jarId = (response['jar_id'] as num?)?.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Joined family jar')),
        );
        if (jarId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FamilyJarDetailScreen(jarId: jarId)));
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _addStar(BuildContext context, int actId, String actTitle) async {
    if (_pendingActIds.contains(actId)) return;

    setState(() {
      _pendingActIds.add(actId);
    });

    final requestId = _generateRequestId();
    try {
      await BackendApi.instance.addJarStar(actId, requestId: requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $actTitle')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingActIds.remove(actId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDD),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(s(18), s(14), s(18), s(16)),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log sadaqah', style: TextStyle(fontSize: s(28), fontWeight: FontWeight.w900, color: const Color(0xFF2F251E))),
                      SizedBox(height: s(4)),
                      Text('Every act should feel easy to spot, tap, and celebrate.', style: TextStyle(fontSize: s(13.2), color: const Color(0xFF6A5E52))),
                    ],
                  ),
                ),
                NotificationActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open notifications from the profile tab or dashboard.')));
                  },
                ),
              ],
            ),
            SizedBox(height: s(14)),
            Container(
              padding: EdgeInsets.all(s(14)),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3ED),
                borderRadius: BorderRadius.circular(s(22)),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: const LiveJarPanel(),
            ),
            SizedBox(height: s(12)),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    scale: scale,
                    title: 'Create family jar',
                    subtitle: 'Build a shared board',
                    icon: Icons.group_add_outlined,
                    onTap: () => _showCreateFamilyJar(context),
                  ),
                ),
                SizedBox(width: s(10)),
                Expanded(
                  child: _ActionButton(
                    scale: scale,
                    title: 'Join jar',
                    subtitle: 'Use an invite code',
                    icon: Icons.meeting_room_outlined,
                    onTap: () => _showJoinFamilyJar(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: s(10)),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchivedJarsScreen()));
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Archived jars'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActsLibraryScreen()));
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Acts library'),
                  ),
                ),
              ],
            ),
            SizedBox(height: s(16)),
            Text('Suggested acts', style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w800, color: const Color(0xFF2F251E))),
            SizedBox(height: s(10)),
            FutureBuilder<List<DailyAct>>(
              future: BackendApi.instance.getDailyActs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StateCard(message: 'Loading suggested acts...');
                }

                if (snapshot.hasError) {
                  return _StateCard(message: 'Suggested acts unavailable', detail: snapshot.error.toString());
                }

                final acts = snapshot.data ?? const <DailyAct>[];
                if (acts.isEmpty) {
                  return const _StateCard(
                    message: 'No suggested acts yet',
                    detail: 'Once the seed data loads, this section will show more curated ideas.',
                  );
                }

                return Column(
                  children: acts.map((act) {
                    final busy = _pendingActIds.contains(act.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3ED),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE6D6C4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3D5C7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.favorite_outline, color: Color(0xFF8B6842)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(act.title, style: const TextStyle(color: Color(0xFF2F251E), fontSize: 15, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text('${act.category} · Difficulty ${act.difficulty}', style: const TextStyle(color: Color(0xFF6A5E52), fontSize: 12.8)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_circle_outline, color: Color(0xFF8B6842)),
                              onPressed: busy ? null : () => _addStar(context, act.id, act.title),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.scale, required this.title, required this.subtitle, required this.icon, required this.onTap});

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F3ED),
      borderRadius: BorderRadius.circular(s(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(18)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: s(40),
                height: s(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D5C7),
                  borderRadius: BorderRadius.circular(s(14)),
                ),
                child: Icon(icon, color: const Color(0xFF8B6842), size: s(22)),
              ),
              SizedBox(height: s(10)),
              Text(title, style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w800, color: const Color(0xFF2F251E))),
              SizedBox(height: s(4)),
              Text(subtitle, style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2F251E))),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6A5E52))),
          ],
        ],
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  const _BottomSheetCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3ED),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFE3D5C7), borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2F251E))),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 13.2, color: Color(0xFF6A5E52), height: 1.4)),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.controller, required this.label, required this.hint, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3D5C7)),
        ),
      ),
    );
  }
}

class _SheetHintRow extends StatelessWidget {
  const _SheetHintRow({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hints
          .map(
            (hint) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3D5C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(hint, style: const TextStyle(fontSize: 12, color: Color(0xFF5A4D43), fontWeight: FontWeight.w600)),
            ),
          )
          .toList(),
    );
  }
}