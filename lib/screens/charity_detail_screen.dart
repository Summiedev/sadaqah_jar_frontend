import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_api.dart';

class CharityDetailScreen extends StatefulWidget {
  const CharityDetailScreen({super.key, required this.charityId});

  final int charityId;

  @override
  State<CharityDetailScreen> createState() => _CharityDetailScreenState();
}

class _CharityDetailScreenState extends State<CharityDetailScreen> {
  late Future<CharityDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getCharity(widget.charityId);
  }

  void _retry() {
    setState(() {
      _future = BackendApi.instance.getCharity(widget.charityId);
    });
  }

  Future<void> _openWebsite(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Only https:// charity URLs are allowed.');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open website.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      appBar: AppBar(
        title: const Text('Charity Details'),
        backgroundColor: const Color(0xFFEDECE6),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FutureBuilder<CharityDetail>(
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
                    Text('Failed to load charity', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              );
            }

            final charity = snapshot.data;
            if (charity == null) {
              return const Center(child: Text('Charity not found.'));
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(20)),
              children: [
                Text(charity.name, style: TextStyle(fontSize: s(24), fontWeight: FontWeight.w800, color: const Color(0xFF2F2A28))),
                SizedBox(height: s(8)),
                Wrap(
                  spacing: s(8),
                  runSpacing: s(8),
                  children: [
                    _StatusBadge(label: charity.isVerified ? 'Verified' : 'Unverified', isPositive: charity.isVerified, scale: scale),
                    _StatusBadge(label: charity.isActive ? 'Active' : 'Inactive', isPositive: charity.isActive, scale: scale),
                    if (charity.isFeatured) _StatusBadge(label: 'Featured', isPositive: true, scale: scale),
                    if (charity.category != null && charity.category!.isNotEmpty) _SimpleBadge(label: charity.category!, scale: scale),
                  ],
                ),
                SizedBox(height: s(14)),
                if (charity.description != null && charity.description!.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(s(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3ED),
                      borderRadius: BorderRadius.circular(s(16)),
                    ),
                    child: Text(
                      charity.description!,
                      style: TextStyle(fontSize: s(14), color: const Color(0xFF4F463F), height: 1.45),
                    ),
                  ),
                SizedBox(height: s(14)),
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
                      Text('Website', style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52))),
                      SizedBox(height: s(4)),
                      SelectableText(
                        charity.websiteUrl,
                        style: TextStyle(fontSize: s(14), color: const Color(0xFF0E7276), fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: s(12)),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            try {
                              await _openWebsite(charity.websiteUrl);
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Visit charity site'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s(12)),
                if (!charity.isVerified)
                  Text(
                    'This charity is not verified yet. No in-app donation handoff is wired, so use the external site only.',
                    style: TextStyle(fontSize: s(12), color: const Color(0xFF7A5B3E)),
                  )
                else
                  Text(
                    'No in-app donation flow is available, so the site opens externally.',
                    style: TextStyle(fontSize: s(12), color: const Color(0xFF7A5B3E)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isPositive, required this.scale});

  final String label;
  final bool isPositive;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(5)),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFEAF3E4) : const Color(0xFFF7E9E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: s(11),
          color: isPositive ? const Color(0xFF4E7A39) : const Color(0xFF9B5F47),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SimpleBadge extends StatelessWidget {
  const _SimpleBadge({required this.label, required this.scale});

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
