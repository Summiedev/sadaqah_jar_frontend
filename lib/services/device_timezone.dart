import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Resolves the device's IANA timezone (e.g. "Africa/Lagos") instead of the
/// ambiguous abbreviation returned by `DateTime.now().timeZoneName` (e.g.
/// "WAT", "CET", "EST"), which is NOT a valid IANA timezone identifier.
///
/// [M4] The abbreviation is not reliable for `tz.getLocation()` or for the
/// backend's scheduling logic. This resolver prefers the platform's own
/// timezone name and falls back safely to UTC rather than crashing.
class DeviceTimezone {
  DeviceTimezone._();
  static final instance = DeviceTimezone._();

  /// Returns a valid IANA timezone string if resolvable, otherwise "UTC".
  /// Never throws; callers can rely on it for scheduling.
  Future<String> resolveIanaTimezone() async {
    final platformName = await _platformTimezone();
    if (platformName != null && _isValidIana(platformName)) {
      return platformName;
    }
    return 'UTC';
  }

  Future<String?> _platformTimezone() async {
    try {
      // flutter_timezone package (if present) returns a real IANA identifier.
      // Fall back to the platform channel if available.
      const MethodChannel channel = MethodChannel('flutter_timezone');
      final value = await channel.invokeMethod<String>('getLocalTimezone');
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // Platform channel unavailable - fall through.
    }
    // Last resort: attempt to map the abbreviation to a best-guess IANA zone.
    return _guessFromAbbreviation(DateTime.now().timeZoneName);
  }

  bool _isValidIana(String name) {
    try {
      tz.getLocation(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Conservative mapping from ambiguous abbreviations to a likely IANA zone.
  /// Only used when the platform channel is unavailable; NEVER used as the
  /// primary source of truth.
  String? _guessFromAbbreviation(String abbreviation) {
    final upper = abbreviation.toUpperCase();
    const map = <String, String>{
      'WAT': 'Africa/Lagos',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'EET': 'Europe/Athens',
      'EEST': 'Europe/Athens',
      'IST': 'Asia/Kolkata',
      'PKT': 'Asia/Karachi',
      'GST': 'Asia/Dubai',
      'GMT': 'UTC',
      'UTC': 'UTC',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'AST': 'America/Halifax',
      'ADT': 'America/Halifax',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney',
    };
    return map[upper];
  }

  /// Ensures the tz database is initialized and the local location is set to
  /// a valid IANA zone. Safe fallback to UTC.
  Future<void> ensureTimezoneInitialized() async {
    tzdata.initializeTimeZones();
    final zoneName = await resolveIanaTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}

/// Returns a stable integer ID for a scheduled reminder based on its logical
/// identity (type + optional date key). This is the deterministic identity
/// that prevents duplicate Fajr #1, Fajr #2, Fajr #3 when the app opens
/// repeatedly for the same date.
int reminderScheduleId(String reminderType, {String? dateKey}) {
  const base = 2000; // Keep calendar range below Android's int max.
  final prefix = reminderType.toLowerCase();
  // Simple deterministic hash from the identity string.
  final identity = '$prefix${dateKey ?? ''}';
  final prime = 31;
  var hash = 7;
  for (final code in identity.codeUnits) {
    hash = (hash * prime + code) & 0xffff;
  }
  return base + hash;
}
