import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';

/// Qibla service: compute bearing to the Kaaba and expose a stream that
/// combines device heading with qibla bearing so UI can show a live pointer.
class QiblaService {
  QiblaService._();
  static final instance = QiblaService._();

  // Coordinates of the Kaaba (Makkah)
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLon = 39.826206;

  /// Compute the initial bearing from (lat1, lon1) to Kaaba in degrees.
  double computeQiblaBearing(double lat, double lon) {
    final phi1 = _degToRad(lat);
    final phi2 = _degToRad(_kaabaLat);
    final deltaLambda = _degToRad(_kaabaLon - lon);
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final bearing = (_radToDeg(math.atan2(y, x)) + 360) % 360;
    return bearing;
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;

  /// Stream combining compass heading (device) and qibla bearing.
  /// Emits the angle the UI should rotate (degrees clockwise from north).
  Stream<double> qiblaAngleStream({
    required double latitude,
    required double longitude,
  }) {
    final qiblaBearing = computeQiblaBearing(latitude, longitude);
    return (FlutterCompass.events ?? const Stream.empty()).map((event) {
      final heading = event.heading ?? 0.0; // degrees from North
      // Calculate the rotation (how many degrees to rotate a pointer) so that
      // pointer points to qibla: relative = (qiblaBearing - heading)
      final relative = (qiblaBearing - heading) % 360;
      return relative < 0 ? relative + 360 : relative;
    });
  }
}
