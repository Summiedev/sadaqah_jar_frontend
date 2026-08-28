import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: kClayLight,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_AdminAnalyticsBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No analytics available.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              const Text(
                'Top acts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
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
                            color: kBronze,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Donation intents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (data.donationIntents.isEmpty)
                const Text('No donation intent data.')
              else
                ...data.donationIntents.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_border),
                    title: Text('Charity #${item.charityId}'),
                    trailing: Text(item.count.toString()),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
