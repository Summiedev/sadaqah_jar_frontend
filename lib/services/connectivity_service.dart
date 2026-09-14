import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize(WidgetRef ref, {void Function()? onBecameOnline}) {
    _connectivity.checkConnectivity().then((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      ref.read(isOnlineProvider.notifier).state = online;
      if (online) onBecameOnline?.call();
    });

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      ref.read(isOnlineProvider.notifier).state = online;
      if (online) onBecameOnline?.call();
    });
  }

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final isOnlineProvider = StateProvider<bool>((ref) => true);
