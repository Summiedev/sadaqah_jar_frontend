import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';
import '../../widgets/mizan_async_state.dart';
import '../../widgets/mizan_surface.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _rangeDays = 30;
  late Future<AdminAnalyticsOverview> _future = _load();

  Future<AdminAnalyticsOverview> _load() {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _rangeDays - 1));
    return BackendApi.instance.getAdminAnalyticsOverview(
      startDate: start,
      endDate: end,
    );
  }

  void _refresh() => setState(() => _future = _load());

  void _changeRange(int days) {
    if (days == _rangeDays) return;
    setState(() {
      _rangeDays = days;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh analytics',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<AdminAnalyticsOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MizanLoadingState(label: 'Loading analytics...');
          }
          if (snapshot.hasError) {
            return MizanErrorState(
              title: 'Could not load analytics',
              message: backendErrorMessage(
                snapshot.error!,
                fallback: 'We could not load analytics right now.',
              ),
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
          return _AnalyticsView(
            data: data,
            rangeDays: _rangeDays,
            onRangeChanged: _changeRange,
          );
        },
      ),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({
    required this.data,
    required this.rangeDays,
    required this.onRangeChanged,
  });

  final AdminAnalyticsOverview data;
  final int rangeDays;
  final ValueChanged<int> onRangeChanged;

  int _value(Map<String, int> values, String key) => values[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final users = data.users;
    final activity = data.activity;
    return ListView(
      padding: MizanSpacing.screen,
      children: [
        Row(
          children: [
            Text(
              'Overview',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            DropdownButton<int>(
              value: rangeDays,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
              ],
              onChanged: (value) {
                if (value != null) onRangeChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: MizanSpacing.md),
        _MetricGrid(
          items: [
            ('Registered users', _value(users, 'total')),
            ('Active, 30 days', _value(users, 'active_30_days')),
            ('Returning users', _value(users, 'returning')),
            ('New today', _value(users, 'new_today')),
            ('New this week', _value(users, 'new_this_week')),
            ('New this month', _value(users, 'new_this_month')),
          ],
        ),
        const SizedBox(height: MizanSpacing.xl),
        _SectionTitle('Activity in selected range'),
        const SizedBox(height: MizanSpacing.md),
        _MetricGrid(
          items: [
            ('Journey events', _value(activity, 'journey_events')),
            ('Reflections', _value(activity, 'reflections')),
            ('Sadaqah records', _value(activity, 'sadaqah_records')),
            ('Quran/book saves', _value(activity, 'books_saved')),
            ('Donation intents', _value(activity, 'donation_intents')),
            ('Broadcast views', _value(activity, 'broadcast_views')),
            ('Broadcast clicks', _value(activity, 'broadcast_clicks')),
            ('Activity completions', _value(activity, 'completions')),
          ],
        ),
        const SizedBox(height: MizanSpacing.xl),
        _SectionTitle('Daily active users'),
        const SizedBox(height: MizanSpacing.md),
        if (data.dailyActiveUsers.isEmpty)
          Text(
            'No activity was recorded in this period.',
            style: TextStyle(color: colors.textSecondary),
          )
        else
          MizanSurface(
            padding: const EdgeInsets.fromLTRB(10, 18, 18, 12),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: colors.primary,
                      dotData: const FlDotData(show: false),
                      spots: [
                        for (var index = 0;
                            index < data.dailyActiveUsers.length;
                            index++)
                          FlSpot(
                            index.toDouble(),
                            data.dailyActiveUsers[index].count.toDouble(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: MizanSpacing.lg),
        Text(
          'Daily active: ${_value(users, 'daily_active')}  |  Weekly active: ${_value(users, 'weekly_active')}  |  Monthly active: ${_value(users, 'monthly_active')}',
          style: TextStyle(color: colors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _MetricCard(
        title: items[index].$1,
        value: items[index].$2.toString(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: MizanSpacing.xs),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
