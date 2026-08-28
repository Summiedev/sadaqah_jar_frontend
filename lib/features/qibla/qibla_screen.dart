import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_extensions.dart';
import '../../services/location_service.dart';
import '../../services/qibla_service.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  Stream<double>? _angleStream;
  bool _hasLocation = false;
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      double? lat;
      double? lon;
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      } else {
        final stored = await LocationService.instance.getStoredPosition();
        lat = stored?['lat'];
        lon = stored?['lon'];
      }
      if (!mounted) return;
      if (lat != null && lon != null) {
        setState(() {
          _lat = lat;
          _lon = lon;
          _hasLocation = true;
          _angleStream = QiblaService.instance.qiblaAngleStream(
            latitude: lat!,
            longitude: lon!,
          );
        });
      } else {
        setState(() {
          _hasLocation = false;
          _angleStream = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasLocation = false;
        _angleStream = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Qibla'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 0 : 10,
        scrolledUnderElevation: dark ? 0 : 10,
        shadowColor: colors.scrim.withValues(alpha: dark ? 0 : 0.18),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                18,
                compact ? 16 : 20,
                26,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                _QiblaHeroCard(lat: _lat, lon: _lon, hasLocation: _hasLocation),
                const SizedBox(height: 16),
                if (!_hasLocation || _angleStream == null)
                  _LocationRequiredCard(onEnable: _enableLocation)
                else
                  StreamBuilder<double>(
                    stream: _angleStream,
                    builder: (context, snapshot) {
                      final angle = snapshot.data ?? 0;
                      return Column(
                        children: [
                          _CompassCard(angle: angle),
                          const SizedBox(height: 14),
                          const _GuidanceCard(),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _enableLocation() async {
    final granted = await LocationService.instance.requestPermission();
    if (granted) {
      await LocationService.instance.getCurrentPosition();
      await _initStream();
    }
  }
}

class _QiblaHeroCard extends StatelessWidget {
  const _QiblaHeroCard({
    required this.lat,
    required this.lon,
    required this.hasLocation,
  });

  final double? lat;
  final double? lon;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow:
            dark
                ? null
                : [
                  BoxShadow(
                    color: colors.scrim.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_rounded, color: colors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibla Finder',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasLocation && lat != null && lon != null
                      ? 'Using ${lat!.toStringAsFixed(2)}, ${lon!.toStringAsFixed(2)}'
                      : 'Find the direction of the Kaaba from your current location.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassCard extends StatelessWidget {
  const _CompassCard({required this.angle});

  final double angle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size =
        math
            .min(MediaQuery.sizeOf(context).width - 64, 330)
            .clamp(248.0, 330.0)
            .toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow:
            dark
                ? null
                : [
                  BoxShadow(
                    color: colors.scrim.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                ),
                for (var i = 0; i < 36; i++)
                  Transform.rotate(
                    angle: (i / 36) * math.pi * 2,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: i % 3 == 0 ? 3 : 1.5,
                        height: i % 3 == 0 ? 16 : 8,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                Positioned(top: 30, child: _CompassLabel('N')),
                Positioned(right: 32, child: _CompassLabel('E')),
                Positioned(bottom: 30, child: _CompassLabel('S')),
                Positioned(left: 32, child: _CompassLabel('W')),
                Transform.rotate(
                  angle: angle * (math.pi / 180),
                  child: Icon(
                    Icons.navigation_rounded,
                    size: size * 0.48,
                    color: colors.primary,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surfaceElevated, width: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${angle.toStringAsFixed(0)} deg',
            style: TextStyle(
              color: colors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Turn gently until the arrow settles toward Qibla.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  const _CompassLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep the phone flat and away from magnets for the clearest compass reading.',
              style: TextStyle(color: colors.onPrimaryContainer, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRequiredCard extends StatelessWidget {
  const _LocationRequiredCard({required this.onEnable});
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 42, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            'Location required',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grant location access to enable the Qibla compass.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onEnable,
            icon: const Icon(Icons.my_location_outlined),
            label: const Text('Enable location'),
          ),
        ],
      ),
    );
  }
}
