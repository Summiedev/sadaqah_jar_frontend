import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/theme_extensions.dart';
import '../services/backend_api.dart';

/// Checks once per app session so route changes cannot repeatedly show a campaign.
class BroadcastHost extends StatefulWidget {
  const BroadcastHost({
    required this.child,
    required this.navigatorKey,
    required this.onDeepLink,
    super.key,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final void Function(String path) onDeepLink;

  @override
  State<BroadcastHost> createState() => _BroadcastHostState();
}

class _BroadcastHostState extends State<BroadcastHost> {
  bool _checked = false;
  bool _checking = false;
  Timer? _retryTimer;
  final Set<int> _shown = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checked || _checking) return;
    _checking = true;
    try {
      // The host is mounted before authentication completes. Do not consume
      // the one session check with an unauthenticated 401.
      if (!await BackendApi.instance.hasToken()) {
        _scheduleRetry();
        return;
      }
      final broadcasts = await BackendApi.instance.getActiveBroadcasts();
      _checked = true;
      if (!mounted) return;
      BroadcastItem? next;
      for (final item in broadcasts) {
        if (!_shown.contains(item.id)) {
          next = item;
          break;
        }
      }
      if (next == null) return;
      _shown.add(next.id);
      await _show(next);
    } catch (error) {
      debugPrint('Broadcast check failed: $error');
      _scheduleRetry();
    } finally {
      _checking = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) unawaited(_check());
    });
  }

  Future<void> _show(BroadcastItem broadcast) async {
    // The receipt is telemetry, not a prerequisite for showing the campaign.
    // A slow API must never prevent the user from seeing the announcement.
    unawaited(BackendApi.instance.recordBroadcastView(broadcast.id).catchError((_) {}));
    final navigatorContext = widget.navigatorKey.currentContext;
    if (!mounted || navigatorContext == null) return;
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        return AlertDialog(
          title: Text(broadcast.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (broadcast.imageUrl?.isNotEmpty == true) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(broadcast.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(broadcast.body, style: TextStyle(color: colors.textSecondary, height: 1.45)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                unawaited(BackendApi.instance.recordBroadcastDismissal(broadcast.id));
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            if (broadcast.ctaLabel?.isNotEmpty == true && broadcast.ctaLink?.isNotEmpty == true)
              FilledButton(onPressed: () => _openCta(dialogContext, broadcast), child: Text(broadcast.ctaLabel!)),
          ],
        );
      },
    );
  }

  Future<void> _openCta(BuildContext dialogContext, BroadcastItem broadcast) async {
    final link = broadcast.ctaLink!;
    await BackendApi.instance.recordBroadcastClick(broadcast.id).catchError((_) {});
    unawaited(BackendApi.instance.recordBroadcastDismissal(broadcast.id).catchError((_) {}));
    if (!dialogContext.mounted) return;
    Navigator.pop(dialogContext);
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (dialogContext.mounted) {
      widget.onDeepLink(link);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
