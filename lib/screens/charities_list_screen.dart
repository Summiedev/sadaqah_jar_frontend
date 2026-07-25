import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_api.dart';

const _ink = Color(0xFF30261F);
const _muted = Color(0xFF76695E);
const _bronze = Color(0xFF8B6842);
const _paper = Color(0xFFFFFCF8);
const _line = Color(0xFFE8DDD1);
const _surface = Color(0xFFF8F2EA);

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
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Verified Donations', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, color: _ink)),
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: _ink),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<CharityPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _bronze));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 40, color: _muted),
                      const SizedBox(height: 12),
                      Text('Could not load charities', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                        style: FilledButton.styleFrom(backgroundColor: _bronze),
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
                      Icon(Icons.volunteer_activism_outlined, size: 48, color: _line),
                      const SizedBox(height: 12),
                      Text('No verified donations yet', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Check back soon for trusted places to give.', style: TextStyle(color: _muted, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
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
          color: _paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E3D4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.volunteer_activism_outlined, color: _bronze, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charity.name,
                    style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  if (charity.category != null && charity.category!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      charity.category!,
                      style: const TextStyle(color: _bronze, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ],
                  if (charity.description != null && charity.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      charity.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E3D4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.open_in_new_rounded, color: _bronze, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
