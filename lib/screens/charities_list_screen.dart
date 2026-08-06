import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../services/backend_api.dart';

class CharitiesListScreen extends StatefulWidget {
  const CharitiesListScreen({super.key});

  @override
  State<CharitiesListScreen> createState() => _CharitiesListScreenState();
}

class _CharitiesListScreenState extends State<CharitiesListScreen> {
  late Future<CharityPage> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.instance.getCharities(limit: 50);
  }

  void _refresh() {
    setState(() {
      _future = BackendApi.instance.getCharities(limit: 50);
    });
  }

  Future<void> _openWebsite(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid website link.')),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the website.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('Verified Donations', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, color: kInk)),
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: kInk),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<CharityPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kBronze));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 40, color: kMuted),
                      const SizedBox(height: 12),
                      Text('Could not load charities', style: TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                        style: FilledButton.styleFrom(backgroundColor: kBronze),
                      ),
                    ],
                  ),
                ),
              );
            }

            final charities = snapshot.data?.data ?? const [];

            if (charities.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volunteer_activism_outlined, size: 48, color: kLine),
                      const SizedBox(height: 12),
                      Text('No verified donations yet', style: TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Check back soon for trusted places to give.', style: TextStyle(color: kMuted, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: charities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final charity = charities[index];
                return _CharityCard(
                  charity: charity,
                  onTap: () => _openWebsite(charity.websiteUrl),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CharityCard extends StatelessWidget {
  const _CharityCard({required this.charity, required this.onTap});

  final CharityItem charity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLine),
          boxShadow: [
            BoxShadow(color: kInk.withValues(alpha: 0.05), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kSoftBronze,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.volunteer_activism_outlined, color: kBronze, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charity.name,
                    style: const TextStyle(color: kInk, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  if (charity.category != null && charity.category!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      charity.category!,
                      style: const TextStyle(color: kBronze, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ],
                  if (charity.description != null && charity.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      charity.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kMuted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kSoftBronze,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.open_in_new_rounded, color: kBronze, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
