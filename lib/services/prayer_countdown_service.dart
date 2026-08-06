import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';

class PrayerTime {
  final String name;
  final int hour;
  final int minute;

  const PrayerTime({required this.name, required this.hour, required this.minute});
}

// Local fallback times used if remote fetch fails.
const List<PrayerTime> kPrayerTimesFallback = [
  PrayerTime(name: 'Fajr', hour: 5, minute: 15),
  PrayerTime(name: 'Dhuhr', hour: 12, minute: 15),
  PrayerTime(name: 'Asr', hour: 15, minute: 45),
  PrayerTime(name: 'Maghrib', hour: 18, minute: 45),
  PrayerTime(name: 'Isha', hour: 20, minute: 15),
];

class PrayerCountdownService {
  PrayerCountdownService._();
  static final instance = PrayerCountdownService._();

  static const _prefsKeyPrefix = 'prayer_times_'; // keyed by YYYY-MM-DD

  /// Fetches prayer times for [date] using stored/available location.
  /// Falls back to local constants on error.
  Future<List<PrayerTime>> getTimingsForDate(DateTime date, {bool forceRefresh = false}) async {
    final key = '$_prefsKeyPrefix${date.toIso8601String().substring(0, 10)}';
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          return _fromMap(decoded);
        } catch (_) {}
      }
    }

    // Attempt remote fetch
    try {
      final pos = await LocationService.instance.getStoredPosition() ?? await LocationService.instance.getCurrentPosition().then((p) => p == null ? null : {'lat': p.latitude, 'lon': p.longitude});
      if (pos != null) {
        final lat = pos['lat'];
        final lon = pos['lon'];
        final uri = Uri.https('api.aladhan.com', '/v1/timings/${date.toUtc().millisecondsSinceEpoch ~/ 1000}', {
          'latitude': '$lat',
          'longitude': '$lon',
          'method': '2', // ISNA default; app can expose method selection later
        });
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>?;
          final timings = data?['timings'] as Map<String, dynamic>?;
          if (timings != null) {
            final map = <String, dynamic>{
              'Fajr': timings['Fajr'],
              'Dhuhr': timings['Dhuhr'],
              'Asr': timings['Asr'],
              'Maghrib': timings['Maghrib'],
              'Isha': timings['Isha'],
            };
            await prefs.setString(key, jsonEncode(map));
            return _fromMap(map);
          }
        }
      }
    } catch (_) {}

    // Fallback
    return kPrayerTimesFallback;
  }

  /// Force-refreshes timings for [date] by clearing any cached entry and fetching anew.
  Future<List<PrayerTime>> refreshTimingsForDate(DateTime date) async {
    final key = '$_prefsKeyPrefix${date.toIso8601String().substring(0, 10)}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    return getTimingsForDate(date, forceRefresh: true);
  }

  List<PrayerTime> _fromMap(Map<String, dynamic> map) {
    PrayerTime parse(String name, dynamic raw) {
      final s = (raw ?? '') as String;
      // Timings from APIs sometimes include annotations (e.g. "05:15 (BST)").
      // Extract the first HH:MM occurrence robustly.
      final match = RegExp(r"(\d{1,2}):(\d{2})").firstMatch(s);
      if (match != null) {
        final h = int.tryParse(match.group(1)!) ?? 0;
        final m = int.tryParse(match.group(2)!) ?? 0;
        return PrayerTime(name: name, hour: h, minute: m);
      }
      return PrayerTime(name: name, hour: 0, minute: 0);
    }

    return [
      parse('Fajr', map['Fajr']),
      parse('Dhuhr', map['Dhuhr']),
      parse('Asr', map['Asr']),
      parse('Maghrib', map['Maghrib']),
      parse('Isha', map['Isha']),
    ];
  }

  /// Returns the next prayer after [now], consulting today's and tomorrow's timings as needed.
  Future<PrayerTime?> nextPrayer(DateTime now) async {
    final today = await getTimingsForDate(now);
    final minutes = now.hour * 60 + now.minute;
    for (final p in today) {
      final pMinutes = p.hour * 60 + p.minute;
      if (pMinutes > minutes) return p;
    }
    // Not found today -> return first prayer tomorrow
    final tomorrow = await getTimingsForDate(now.add(const Duration(days: 1)));
    return tomorrow.isNotEmpty ? tomorrow.first : null;
  }

  Future<int> minutesUntilNextPrayer(DateTime now) async {
    final prayer = await nextPrayer(now);
    if (prayer == null) return 0;
    final nowMinutes = now.hour * 60 + now.minute;
    final prayerMinutes = prayer.hour * 60 + prayer.minute;
    if (prayerMinutes > nowMinutes) return prayerMinutes - nowMinutes;
    return (24 * 60 - nowMinutes) + prayerMinutes;
  }

  String formatCountdown(int minutes) {
    if (minutes <= 0) return 'now';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}
