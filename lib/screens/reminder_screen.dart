import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(22), s(18), s(22), s(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Momentum',
                style: TextStyle(
                  fontSize: s(40 / 2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1A18),
                ),
              ),
              SizedBox(height: s(16)),
              FutureBuilder<FridayStats>(
                future: BackendApi.instance.getFridayStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(s(16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFD),
                      borderRadius: BorderRadius.circular(s(10)),
                      border: Border.all(color: const Color(0xFFD3E2C4), width: 1),
                    ),
                    child: Text(
                      'Weekly momentum: ${stats?.fridayStars ?? 0}\nActive users: ${stats?.activeUsers ?? 0}',
                      style: TextStyle(
                        color: const Color(0xFF6A5E52),
                        fontSize: s(16),
                        height: 1.35,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: s(18)),
              Text(
                'Momentum board',
                style: TextStyle(
                  fontSize: s(36 / 2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1A18),
                ),
              ),
              SizedBox(height: s(10)),
              Expanded(
                child: FutureBuilder<List<LeaderboardEntry>>(
                  future: BackendApi.instance.getFridayLeaderboard(limit: 10),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final entries = snapshot.data ?? const <LeaderboardEntry>[];
                    if (entries.isEmpty) {
                      return const Center(child: Text('No momentum entries yet.'));
                    }

                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => SizedBox(height: s(10)),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _MomentumTile(
                          scale: scale,
                          title: 'User #${entry.userId}',
                          time: '${entry.stars} stars',
                          rank: index + 1,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentumTile extends StatelessWidget {
  const _MomentumTile({required this.scale, required this.title, required this.time, required this.rank});

  final double scale;
  final String title;
  final String time;
  final int rank;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(s(10)),
      ),
      child: Row(
        children: [
          Container(
            width: s(36),
            height: s(36),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1EA),
              borderRadius: BorderRadius.circular(s(9)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(color: const Color(0xFF8C6A4A), fontSize: s(14), fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: s(16),
                color: const Color(0xFF423933),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: s(14), color: const Color(0xFF6A5E52)),
          ),
        ],
      ),
    );
  }
}






