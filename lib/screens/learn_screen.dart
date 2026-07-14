import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_api.dart';
import 'charity_detail_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  Future<void> _openCharityWebsite(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Only https:// charity URLs are allowed.');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open charity website.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(22), s(18), s(22), s(18)),
          child: ListView(
            children: [
              Text(
                'Donate',
                style: TextStyle(
                  fontSize: s(40 / 2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1A18),
                ),
              ),
              SizedBox(height: s(16)),
              FutureBuilder<List<CharityItem>>(
                future: BackendApi.instance.getFeaturedCharities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(s(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFD),
                        borderRadius: BorderRadius.circular(s(10)),
                        border: Border.all(color: const Color(0xFFD3E2C4), width: 1),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(s(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFD),
                        borderRadius: BorderRadius.circular(s(10)),
                        border: Border.all(color: const Color(0xFFD3E2C4), width: 1),
                      ),
                      child: Text('Failed to load featured donations: ${snapshot.error}'),
                    );
                  }

                  final featured = snapshot.data ?? const <CharityItem>[];
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(s(16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFD),
                      borderRadius: BorderRadius.circular(s(10)),
                      border: Border.all(color: const Color(0xFFD3E2C4), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Featured Donations',
                          style: TextStyle(
                            color: const Color(0xFF1C1A19),
                            fontSize: s(18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: s(10)),
                        if (featured.isEmpty)
                          Text(
                            'No featured donations available right now.',
                            style: TextStyle(color: const Color(0xFF8E8C88), fontSize: s(14)),
                          )
                          else
                          ...featured.take(2).map(
                            (charity) => Padding(
                              padding: EdgeInsets.only(bottom: s(10)),
                              child: _CharitySpotlight(
                                scale: scale,
                                charity: charity,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => CharityDetailScreen(charityId: charity.id)),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: s(18)),
              Text(
                'Donation Directory',
                style: TextStyle(
                  fontSize: s(36 / 2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1A18),
                ),
              ),
              SizedBox(height: s(12)),
              FutureBuilder<CharityPage>(
                future: BackendApi.instance.getCharities(limit: 12),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load donations: ${snapshot.error}'));
                  }

                  final charities = snapshot.data?.data ?? const <CharityItem>[];
                  if (charities.isEmpty) {
                    return const Center(child: Text('No donations available right now.'));
                  }

                  return ListView.separated(
                    itemCount: charities.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => SizedBox(height: s(12)),
                    itemBuilder: (context, index) {
                      final charity = charities[index];
                      return _CharityCard(
                        scale: scale,
                        charity: charity,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CharityDetailScreen(charityId: charity.id)),
                          );
                        },
                        onOpenWebsite: (url) => _openCharityWebsite(context, url),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharitySpotlight extends StatelessWidget {
  const _CharitySpotlight({required this.scale, required this.charity, this.onTap});

  final double scale;
  final CharityItem charity;
  final VoidCallback? onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3D5C7),
      borderRadius: BorderRadius.circular(s(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(10)),
        child: Padding(
          padding: EdgeInsets.all(s(12)),
          child: Row(
            children: [
              Container(
                width: s(42),
                height: s(42),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F1EA),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Icon(Icons.volunteer_activism, color: const Color(0xFF8C6A4A), size: s(22)),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(charity.name, style: TextStyle(color: const Color(0xFF423933), fontSize: s(16), fontWeight: FontWeight.w700)),
                    SizedBox(height: s(3)),
                    Text(
                      charity.description ?? charity.category ?? 'Featured donation partner',
                      style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(13)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharityCard extends StatelessWidget {
  const _CharityCard({required this.scale, required this.charity, required this.onTap, required this.onOpenWebsite});

  final double scale;
  final CharityItem charity;
  final VoidCallback onTap;
  final Future<void> Function(String url) onOpenWebsite;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3D5C7),
      borderRadius: BorderRadius.circular(s(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(10)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      charity.name,
                      style: TextStyle(color: const Color(0xFF3B3327), fontSize: s(16), fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (charity.isFeatured)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(4)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1EA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Featured', style: TextStyle(color: const Color(0xFF8C6A4A), fontSize: s(11))),
                    ),
                ],
              ),
              SizedBox(height: s(4)),
              Text(
                charity.description ?? 'Open the charity site to learn more about their work.',
                style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(13), height: 1.35),
              ),
              SizedBox(height: s(8)),
              TextButton.icon(
                onPressed: () async {
                  try {
                    await onOpenWebsite(charity.websiteUrl);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open donation page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


