import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_extensions.dart';
import '../services/backend_api.dart';

class CharitiesListScreen extends StatefulWidget {
  const CharitiesListScreen({super.key});

  @override
  State<CharitiesListScreen> createState() => _CharitiesListScreenState();
}

class _CharitiesListScreenState extends State<CharitiesListScreen> {
  late Future<CharityPage> _future = BackendApi.instance.getCharities(
    limit: 50,
  );

  void _refresh() =>
      setState(() {
        _future = BackendApi.instance.getCharities(limit: 50);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Verified Donations',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<CharityPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          if (snapshot.hasError)
            return _EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load donations',
              body: snapshot.error.toString(),
              onRetry: _refresh,
            );
          final donations = snapshot.data?.data ?? const [];
          if (donations.isEmpty)
            return const _EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No verified donations yet',
              body: 'Check back soon for trusted places to give.',
            );
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: donations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _DonationCard(
                donation: donation,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => DonationDetailsScreen(
                              donationId: donation.id,
                              fallback: donation,
                            ),
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class DonationDetailsScreen extends StatefulWidget {
  const DonationDetailsScreen({
    super.key,
    required this.donationId,
    this.fallback,
  });

  final int donationId;
  final CharityItem? fallback;

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  late final Future<CharityDetail> _future = BackendApi.instance.getCharity(
    widget.donationId,
  );

  Future<void> _openExternal(CharityDetail donation) async {
    final raw =
        (donation.externalUrl?.isNotEmpty == true
            ? donation.externalUrl
            : donation.websiteUrl) ??
        '';
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation link is not available.')),
        );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the donation link.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Donation Details',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<CharityDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              widget.fallback == null)
            return const Center(
              child: CircularProgressIndicator(color: kBronze),
            );
          if (snapshot.hasError && widget.fallback == null)
            return const _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Donation unavailable',
              body: 'This campaign may have been closed.',
            );
          final detail = snapshot.data ?? widget.fallback!.asDetail();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              if (detail.imageUrls.isNotEmpty)
                _ImageCarousel(urls: detail.imageUrls),
              const SizedBox(height: 16),
              Text(
                detail.displayTitle,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: context.colors.textPrimary,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (detail.name.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  detail.name,
                  style: const TextStyle(
                    color: kBronze,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    detail.donationType == 'personal'
                        ? 'Personal case'
                        : 'External campaign',
                    kBronze,
                  ),
                  _Chip(detail.statusLabel, detail.statusColor),
                  if (detail.category?.isNotEmpty == true)
                    _Chip(detail.category!, kSage),
                ],
              ),
              if (detail.targetAmount != null) ...[
                const SizedBox(height: 18),
                _DetailProgress(detail: detail),
              ],
              if (detail.description?.trim().isNotEmpty == true)
                _Section(
                  title: detail.donationType == 'personal' ? 'Story' : 'About',
                  body: detail.description!.trim(),
                ),
              if (detail.evidence?.trim().isNotEmpty == true)
                _Section(
                  title: 'Supporting Information',
                  body: detail.evidence!.trim(),
                ),
              if (detail.contactInfo?.trim().isNotEmpty == true)
                _Section(title: 'Contact', body: detail.contactInfo!.trim()),
              if (detail.deadline?.trim().isNotEmpty == true)
                _Section(title: 'Deadline', body: detail.deadline!.trim()),
              if (detail.evidenceUrls.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Evidence Files',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...detail.evidenceUrls.map(
                  (url) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.verified_outlined,
                      color: kBronze,
                    ),
                    title: const Text('Open supporting file'),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap:
                        () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (detail.donationType == 'external')
                FilledButton.icon(
                  onPressed: () => _openExternal(detail),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Continue to Donation Source'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kBronze,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'This is a personal campaign managed by Mizan admins. Use the contact or supporting information above to continue.',
                    style: TextStyle(
                      color: context.colors.onPrimaryContainer,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation, required this.onTap});

  final CharityItem donation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: context.colors.scrim.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 58,
                height: 58,
                color: context.colors.primaryContainer,
                child:
                    donation.imageUrls.isEmpty
                        ? Icon(
                          Icons.volunteer_activism_outlined,
                          color: context.colors.primary,
                        )
                        : Image.network(
                          donation.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.volunteer_activism_outlined,
                                color: context.colors.primary,
                              ),
                        ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: context.colors.textPrimary,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (donation.category?.isNotEmpty == true)
                    Text(
                      donation.category!,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (donation.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      donation.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (donation.targetAmount != null) ...[
                    const SizedBox(height: 8),
                    _ListProgress(donation: donation),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.urls});
  final List<String> urls;
  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder:
                  (_, i) => Image.network(
                    widget.urls[i],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: context.colors.primaryContainer,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: kBronze,
                          ),
                        ),
                  ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_index + 1} of ${widget.urls.length}',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailProgress extends StatelessWidget {
  const _DetailProgress({required this.detail});
  final CharityDetail detail;
  @override
  Widget build(BuildContext context) {
    final target = detail.targetAmount ?? 0.0;
    final raised = detail.amountRaised ?? 0.0;
    final pct =
        target <= 0 ? 0.0 : (raised / target).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${detail.currencySymbol}${raised.toStringAsFixed(0)} / ${detail.currencySymbol}${target.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Georgia',
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: context.colors.primary,
              backgroundColor: context.colors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListProgress extends StatelessWidget {
  const _ListProgress({required this.donation});
  final CharityItem donation;
  @override
  Widget build(BuildContext context) {
    final target = donation.targetAmount ?? 0.0;
    final raised = donation.amountRaised ?? 0.0;
    final pct =
        target <= 0 ? 0.0 : (raised / target).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            color: context.colors.primary,
            backgroundColor: context.colors.primaryContainer,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${donation.currencySymbol}${raised.toStringAsFixed(0)} / ${donation.currencySymbol}${target.toStringAsFixed(0)}',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Georgia',
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: context.colors.textSecondary, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: kBronze),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, height: 1.45),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: kBronze),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _DonationItemText on CharityItem {
  String get displayTitle =>
      (title?.trim().isNotEmpty == true ? title!.trim() : name);
  String get currencySymbol =>
      currency.toUpperCase() == 'NGN' ? '\u20A6' : '$currency ';
}

extension _DonationDetailText on CharityDetail {
  String get displayTitle =>
      (title?.trim().isNotEmpty == true ? title!.trim() : name);
  String get statusLabel => status.replaceAll('_', ' ');
  Color get statusColor =>
      status == 'active'
          ? kSage
          : status == 'goal_reached'
          ? kBronze
          : status == 'completed'
          ? kBronzeLight
          : kDanger;
  String get currencySymbol =>
      currency.toUpperCase() == 'NGN' ? '\u20A6' : '$currency ';
}

extension on CharityItem {
  CharityDetail asDetail() => CharityDetail(
    id: id,
    name: name,
    title: title,
    donationType: donationType,
    caseName: caseName,
    description: description,
    websiteUrl: websiteUrl,
    externalUrl: externalUrl,
    category: category,
    targetAmount: targetAmount,
    amountRaised: amountRaised,
    currency: currency,
    imageUrls: imageUrls,
    status: status,
    deadline: deadline,
    isFeatured: isFeatured,
    isVerified: true,
    isActive: true,
  );
}
