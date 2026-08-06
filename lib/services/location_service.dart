import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_countdown_service.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  static const _latKey = 'user_last_lat';
  static const _lonKey = 'user_last_lon';

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _storePosition(pos.latitude, pos.longitude);
      return pos;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storePosition(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lonKey, lon);
    // Trigger a background refresh of today's prayer times when position changes.
    try {
      PrayerCountdownService.instance.refreshTimingsForDate(DateTime.now());
    } catch (_) {}
  }

  Future<Map<String, double>?> getStoredPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);
    if (lat == null || lon == null) return null;
    return {'lat': lat, 'lon': lon};
  }

  Future<void> setManualPosition(double lat, double lon) async {
    await _storePosition(lat, lon);
  }
}
