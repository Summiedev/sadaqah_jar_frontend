import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiryNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Called by SessionController when a confirmed expiry occurs.
  void notifyExpired() {
    state = true;
  }

  /// Called by the shell after showing the one-time message.
  void consume() {
    state = false;
  }
}

final sessionExpiryProvider = NotifierProvider<SessionExpiryNotifier, bool>(
  SessionExpiryNotifier.new,
);
