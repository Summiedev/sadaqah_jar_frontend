import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/qibla_service.dart';
import '../../services/location_service.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  Stream<double>? _angleStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    try {
      // Try to get a fresh position; fall back to stored position if permission
      // denied or device cannot provide a current fix.
      final pos = await LocationService.instance.getCurrentPosition();
      double? lat;
      double? lon;
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      } else {
        final stored = await LocationService.instance.getStoredPosition();
        if (stored != null) {
          lat = stored['lat'];
          lon = stored['lon'];
        }
      }
      if (lat != null && lon != null) {
        setState(() {
          _angleStream = QiblaService.instance.qiblaAngleStream(latitude: lat!, longitude: lon!);
        });
      } else {
        // No location available; expose a default stream so UI can render.
        setState(() {
          _angleStream = Stream.value(0.0);
        });
      }
    } catch (_) {
      // ignore: avoid_print
      print('Unable to obtain location for Qibla');
      setState(() {
        _angleStream = Stream.value(0.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Finder')),
      body: Center(
        child: _angleStream == null
            ? const CircularProgressIndicator()
            : StreamBuilder<double>(
                stream: _angleStream,
                builder: (context, snapshot) {
                  final angle = snapshot.data ?? 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surfaceVariant,
                              ),
                            ),
                            Transform.rotate(
                              angle: angle * (3.1415926535897932 / 180.0),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 120,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Text('Rotate your device until arrow points to Qibla'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
