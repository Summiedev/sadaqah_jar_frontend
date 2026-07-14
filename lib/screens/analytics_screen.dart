import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<DashboardStats> _statsFuture = BackendApi.instance.getDashboardStats();
  late Future<List<CategoryAnalyticsEntry>> _categoriesFuture = BackendApi.instance.getCategoryAnalytics();
  late Future<Map<String, int>> _heatmapFuture = BackendApi.instance.getHeatmap();

  void _retryStats() {
    setState(() {
      _statsFuture = BackendApi.instance.getDashboardStats();
    });
  }

  void _retryCategories() {
    setState(() {
      _categoriesFuture = BackendApi.instance.getCategoryAnalytics();
    });
  }

  void _retryTrend() {
    setState(() {
      _heatmapFuture = BackendApi.instance.getHeatmap();
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
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFFEDECE6),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(20)),
          children: [
            FutureBuilder<DashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                return _SectionCard(
                  title: 'Stats',
                  scale: scale,
                  child: _AsyncBlock(
                    snapshot: snapshot,
                    onRetry: _retryStats,
                    emptyMessage: 'No stats yet.',
                    builder: (stats) {
                      return Wrap(
                        spacing: s(10),
                        runSpacing: s(10),
                        children: [
                          _MetricChip(label: 'Acts', value: stats.totalActsCompleted.toString(), scale: scale),
                          _MetricChip(label: 'Stars', value: stats.totalStarsEarned.toString(), scale: scale),
                          _MetricChip(label: 'Jars', value: stats.totalJarsCompleted.toString(), scale: scale),
                          _MetricChip(label: 'Streak', value: '${stats.currentStreak}d', scale: scale),
                          _MetricChip(label: 'Best', value: '${stats.longestStreak}d', scale: scale),
                          _MetricChip(label: 'Donations', value: stats.donationsMadeCount.toString(), scale: scale),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: s(14)),
            FutureBuilder<List<CategoryAnalyticsEntry>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                return _SectionCard(
                  title: 'Category breakdown',
                  scale: scale,
                  child: _AsyncBlock(
                    snapshot: snapshot,
                    onRetry: _retryCategories,
                    emptyMessage: 'No category data yet.',
                    builder: (categories) {
                      final total = categories.fold<int>(0, (sum, item) => sum + item.count);
                      if (total == 0) {
                        return const Text('No category activity recorded yet.');
                      }
                      return SizedBox(
                        height: s(240),
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 38,
                                  sections: categories.take(6).map((entry) {
                                    final value = entry.count.toDouble();
                                    return PieChartSectionData(
                                      value: value,
                                      title: entry.category,
                                      radius: 56,
                                      titleStyle: TextStyle(fontSize: s(10), color: Colors.white, fontWeight: FontWeight.w700),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(width: s(12)),
                            Expanded(
                              child: ListView.separated(
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => SizedBox(height: s(8)),
                                itemBuilder: (context, index) {
                                  final item = categories[index];
                                  return _MetricChip(
                                    label: item.category,
                                    value: '${item.count} acts',
                                    scale: scale,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: s(14)),
            FutureBuilder<Map<String, int>>(
              future: _heatmapFuture,
              builder: (context, snapshot) {
                return _SectionCard(
                  title: 'Activity trend',
                  scale: scale,
                  child: _AsyncBlock(
                    snapshot: snapshot,
                    onRetry: _retryTrend,
                    emptyMessage: 'No activity trend yet.',
                    builder: (heatmap) {
                      if (heatmap.isEmpty) {
                        return const Text('No activity yet to chart.');
                      }
                      final entries = heatmap.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                      final values = entries.length > 30 ? entries.sublist(entries.length - 30) : entries;
                      final spots = <FlSpot>[];
                      for (var i = 0; i < values.length; i++) {
                        spots.add(FlSpot(i.toDouble(), values[i].value.toDouble()));
                      }
                      return SizedBox(
                        height: s(240),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                color: const Color(0xFF9B734F),
                                belowBarData: BarAreaData(show: true, color: const Color(0xFF9B734F).withValues(alpha: 0.12)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, required this.scale});

  final String title;
  final Widget child;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(s(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28))),
          SizedBox(height: s(10)),
          child,
        ],
      ),
    );
  }
}

class _AsyncBlock<T> extends StatelessWidget {
  const _AsyncBlock({required this.snapshot, required this.onRetry, required this.emptyMessage, required this.builder});

  final AsyncSnapshot<T> snapshot;
  final VoidCallback onRetry;
  final String emptyMessage;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (snapshot.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(snapshot.error.toString()),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }
    final data = snapshot.data;
    if (data == null) {
      return Text(emptyMessage);
    }
    return builder(data);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.scale});

  final String label;
  final String value;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: s(11), color: const Color(0xFF6A5E52))),
          SizedBox(height: s(2)),
          Text(value, style: TextStyle(fontSize: s(15), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28))),
        ],
      ),
    );
  }
}
