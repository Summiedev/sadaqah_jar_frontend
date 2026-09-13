import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/mizan_async_state.dart';
import '../../widgets/mizan_surface.dart';
import '../../services/backend_api.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<_AdminAnalyticsBundle> _future = _load();

  Future<_AdminAnalyticsBundle> _load() async {
    final results = await Future.wait([
      BackendApi.instance.getAdminDailyUsers(),
      BackendApi.instance.getAdminStarsToday(),
      BackendApi.instance.getAdminTopActs(),
      BackendApi.instance.getAdminDonationIntents(),
    ]);
    return _AdminAnalyticsBundle(
      dailyUsers: results[0] as int,
      starsToday: results[1] as int,
      topActs: results[2] as List<AdminTopActEntry>,
      donationIntents: results[3] as List<AdminDonationIntentEntry>,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_AdminAnalyticsBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MizanLoadingState(label: 'Loading analytics...');
          }
          if (snapshot.hasError) {
            return MizanErrorState(
              message: 'We could not load analytics right now.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const MizanEmptyState(
              icon: Icons.insights_outlined,
              title: 'No analytics yet',
              message: 'There is no analytics data to show yet.',
            );
          }
          return ListView(
            padding: MizanSpacing.screen,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'New users',
                      value: data.dailyUsers.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Stars today',
                      value: data.starsToday.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MizanSpacing.lg),
              Text(
                'Top acts',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MizanSpacing.md),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        (data.topActs
                            .map((e) => e.count)
                            .fold<int>(0, (a, b) => a > b ? a : b)).toDouble() +
                        1,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: List.generate(
                      data.topActs.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.topActs[index].count.toDouble(),
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MizanSpacing.lg),
              Text(
                'Donation intents',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MizanSpacing.sm),
              if (data.donationIntents.isEmpty)
                Text(
                  'No donation intent data.',
                  style: TextStyle(color: colors.textSecondary),
                )
              else
                ...data.donationIntents.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.favorite_border,
                      color: colors.iconSecondary,
                    ),
                    title: Text('Charity #${item.charityId}'),
                    trailing: Text(
                      item.count.toString(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MizanSurface(
      padding: MizanSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: MizanSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAnalyticsBundle {
  _AdminAnalyticsBundle({
    required this.dailyUsers,
    required this.starsToday,
    required this.topActs,
    required this.donationIntents,
  });

  final int dailyUsers;
  final int starsToday;
  final List<AdminTopActEntry> topActs;
  final List<AdminDonationIntentEntry> donationIntents;
}
