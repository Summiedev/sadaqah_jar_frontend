import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusBanner extends ConsumerWidget {

  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pending-sync indicators are intentionally invisible. Adding a sadaqah is
    // offline-first: the act counts locally and immediately, and the durable
    // queue syncs to the server silently in the background. Surfacing "N
    // actions pending sync" only creates confusion - from the user's
    // perspective the act has already been added.
    return const SizedBox.shrink();
  }

}
