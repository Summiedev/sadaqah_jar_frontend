import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/backend_api.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late Future<_StreakViewData> _future;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StreakViewData> _load() async {
    final streak = await BackendApi.instance.getStreak();
    final heatmap = await BackendApi.instance.getHeatmap();
    return _StreakViewData(streak: streak, heatmap: heatmap);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5D6C3),
        title: const Text('Streaks', style: TextStyle(color: Color(0xFF3B3327))),
        iconTheme: const IconThemeData(color: Color(0xFF3B3327)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F2E9), Color(0xFFF1E8DB), Color(0xFFF7F2E9)],
          ),
        ),
        child: FutureBuilder<_StreakViewData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _StateMessage(
                title: 'Could not load streak data.',
                detail: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return _StateMessage(
                title: 'No streak data yet.',
                detail: 'Your activity calendar will appear after your first sadaqah entry.',
                onRetry: _refresh,
                showRetry: false,
              );
            }

            final streak = data.streak;
            final heatmap = data.heatmap;
            final hasActivity = heatmap.isNotEmpty;
            final selectedKey = _dateKey(_selectedDay ?? _focusedDay);
            final selectedCount = heatmap[selectedKey] ?? 0;

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: EdgeInsets.all(s(16)),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _SummaryCard(
                      key: ValueKey('${streak.currentStreak}-${streak.longestStreak}-${streak.source}'),
                      scale: scale,
                      currentStreak: streak.currentStreak,
                      longestStreak: streak.longestStreak,
                      hasActivity: hasActivity,
                      source: streak.source,
                    ),
                  ),
                  SizedBox(height: s(16)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: hasActivity ? _HeatmapLegend(scale: scale) : _EmptyActivityCard(scale: scale),
                  ),
                  SizedBox(height: s(12)),
                  Container(
                    padding: EdgeInsets.all(s(12)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F4EC),
                      borderRadius: BorderRadius.circular(s(16)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6)),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                      lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      rowHeight: 44,
                      daysOfWeekHeight: 24,
                      calendarStyle: CalendarStyle(
                        cellMargin: EdgeInsets.zero,
                        isTodayHighlighted: true,
                        outsideDaysVisible: false,
                        defaultDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                        weekendDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xFF9B734F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFFD9C3A8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: const Color(0xFF3B3327),
                          fontSize: s(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return _HeatCell(
                            count: heatmap[_dateKey(day)] ?? 0,
                            day: day.day,
                            isSelected: isSameDay(day, _selectedDay),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _HeatCell(
                            count: heatmap[_dateKey(day)] ?? 0,
                            day: day.day,
                            isToday: true,
                            isSelected: isSameDay(day, _selectedDay),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _HeatCell(
                            count: heatmap[_dateKey(day)] ?? 0,
                            day: day.day,
                            isSelected: true,
                          );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return _HeatCell(
                            count: 0,
                            day: day.day,
                            isOutside: true,
                          );
                        },
                      ),
                      eventLoader: (day) => heatmap[_dateKey(day)] == null ? const [] : [heatmap[_dateKey(day)]!],
                    ),
                  ),
                  SizedBox(height: s(12)),
                  _DayDetailsCard(
                    scale: scale,
                    dateLabel: _formatLongDate(_selectedDay ?? _focusedDay),
                    stars: selectedCount,
                    empty: selectedCount == 0,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _dateKey(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static String _formatLongDate(DateTime value) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _StreakViewData {
  _StreakViewData({required this.streak, required this.heatmap});

  final StreakInfo streak;
  final Map<String, int> heatmap;
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.title, required this.detail, required this.onRetry, this.showRetry = true});

  final String title;
  final String detail;
  final VoidCallback onRetry;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (showRetry) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.scale,
    required this.currentStreak,
    required this.longestStreak,
    required this.hasActivity,
    required this.source,
  });

  final double scale;
  final int currentStreak;
  final int longestStreak;
  final bool hasActivity;
  final String source;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EC),
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: const Color(0xFFB07B3E), size: s(34)),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActivity ? '$currentStreak day streak' : 'No activity yet',
                  style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327)),
                ),
                SizedBox(height: s(4)),
                Text(
                  hasActivity ? 'Longest run: $longestStreak days' : 'Log your first sadaqah to light up the calendar.',
                  style: TextStyle(fontSize: s(13), color: const Color(0xFF7A5B3E)),
                ),
                SizedBox(height: s(6)),
                Text(
                  'Source: $source',
                  style: TextStyle(fontSize: s(11.5), color: const Color(0xFF8A796B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.count,
    required this.day,
    this.isOutside = false,
    this.isToday = false,
    this.isSelected = false,
  });

  final int count;
  final int day;
  final bool isOutside;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = count == 0
        ? const Color(0xFFEFE6D9)
        : count == 1
            ? const Color(0xFFD8C0A3)
            : count == 2
                ? const Color(0xFFC29A6D)
                : const Color(0xFF9B734F);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9B734F) : color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? const Color(0xFF7A5B3E) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: isOutside || count == 0 ? const Color(0xFF7A6D60) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.scale});

  final double scale;
  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(s(16)),
      ),
      child: Text(
        'No sadaqah logged yet. The calendar will fill up as you add your first act.',
        style: TextStyle(fontSize: s(13), color: const Color(0xFF5A4D43)),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.scale});

  final double scale;
  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const Color(0xFFEFE6D9),
      const Color(0xFFD8C0A3),
      const Color(0xFFC29A6D),
      const Color(0xFF9B734F),
    ];
    return Wrap(
      spacing: s(8),
      runSpacing: s(8),
      children: [
        for (final color in steps)
          Container(
            width: s(18),
            height: s(18),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
        Text('More activity = darker cell', style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
      ],
    );
  }
}

class _DayDetailsCard extends StatelessWidget {
  const _DayDetailsCard({required this.scale, required this.dateLabel, required this.stars, required this.empty});

  final double scale;
  final String dateLabel;
  final int stars;
  final bool empty;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EC),
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel, style: TextStyle(fontSize: s(14), fontWeight: FontWeight.w700, color: const Color(0xFF3B3327))),
          SizedBox(height: s(4)),
          Text(
            empty ? 'No activity on this day.' : '$stars star${stars == 1 ? '' : 's'} logged.',
            style: TextStyle(fontSize: s(13), color: const Color(0xFF7A5B3E)),
          ),
        ],
      ),
    );
  }
}
