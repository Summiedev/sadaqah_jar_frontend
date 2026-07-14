import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ActDetailScreen extends StatefulWidget {
  const ActDetailScreen({super.key, required this.actId});

  final int actId;

  @override
  State<ActDetailScreen> createState() => _ActDetailScreenState();
}

class _ActDetailScreenState extends State<ActDetailScreen> {
  late Future<SadaqahActDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getActDetail(widget.actId);
  }

  void _retry() {
    setState(() {
      _future = BackendApi.instance.getActDetail(widget.actId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      appBar: AppBar(
        title: const Text('Act Details'),
        backgroundColor: const Color(0xFFEDECE6),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FutureBuilder<SadaqahActDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load act', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              );
            }

            final act = snapshot.data;
            if (act == null) {
              return const Center(child: Text('Act not found.'));
            }

            final evidence = act.evidence;
            return ListView(
              padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(20)),
              children: [
                Text(act.title, style: TextStyle(fontSize: s(24), fontWeight: FontWeight.w800, color: const Color(0xFF2F2A28))),
                SizedBox(height: s(8)),
                Wrap(
                  spacing: s(8),
                  runSpacing: s(8),
                  children: [
                    _Badge(label: act.category, scale: scale),
                    _Badge(label: 'Difficulty ${act.difficulty}', scale: scale),
                    _Badge(label: 'Reward x${act.rewardWeight}', scale: scale),
                    if (act.estimatedTimeMinutes != null)
                      _Badge(label: '${act.estimatedTimeMinutes} min', scale: scale),
                  ],
                ),
                SizedBox(height: s(14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(s(14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3ED),
                    borderRadius: BorderRadius.circular(s(16)),
                  ),
                  child: Text(
                    act.description,
                    style: TextStyle(fontSize: s(14), color: const Color(0xFF4F463F), height: 1.45),
                  ),
                ),
                SizedBox(height: s(16)),
                Text('Evidence', style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28))),
                SizedBox(height: s(10)),
                if (evidence == null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(s(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3D5C7),
                      borderRadius: BorderRadius.circular(s(16)),
                    ),
                    child: const Text('No evidence attached to this act yet.'),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(s(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3D5C7),
                      borderRadius: BorderRadius.circular(s(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${evidence.sourceType} - ${evidence.reference}',
                                style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28)),
                              ),
                            ),
                            _EvidenceBadge(label: evidence.isVerified ? 'Verified' : 'Unverified', scale: scale),
                          ],
                        ),
                        if (evidence.grade != null) ...[
                          SizedBox(height: s(6)),
                          Text('Grade: ${evidence.grade}', style: TextStyle(fontSize: s(13), color: const Color(0xFF5A4D43))),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: s(10)),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.only(bottom: s(8)),
                    title: const Text('Full source text'),
                    children: [
                      if (evidence.arabicText != null && evidence.arabicText!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(s(14)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3ED),
                            borderRadius: BorderRadius.circular(s(14)),
                          ),
                          child: SelectableText(
                            evidence.arabicText!,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: s(18), height: 1.7),
                          ),
                        ),
                        SizedBox(height: s(10)),
                      ],
                      if (evidence.englishText != null && evidence.englishText!.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(s(14)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3ED),
                            borderRadius: BorderRadius.circular(s(14)),
                          ),
                          child: SelectableText(
                            evidence.englishText!,
                            style: TextStyle(fontSize: s(14), height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.scale});

  final String label;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(5)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: s(11), color: const Color(0xFF5A4D43), fontWeight: FontWeight.w600)),
    );
  }
}

class _EvidenceBadge extends StatelessWidget {
  const _EvidenceBadge({required this.label, required this.scale});

  final String label;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(5)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: s(11), color: const Color(0xFF6A5E52), fontWeight: FontWeight.w700)),
    );
  }
}
