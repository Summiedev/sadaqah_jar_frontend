import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_api.dart';
import '../services/offline_action_queue.dart';
import '../services/push_notification_service.dart';
import '../services/websocket_service.dart';
import 'session_expiry_notifier.dart';

enum SessionStatus { loading, anonymous, authenticated }

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final session = SessionController();
  session.restore();
  return session;
});

class SessionController extends ChangeNotifier {
  SessionController() {
    // When any authenticated request exhausts its refresh/retry and the
    // session can't be restored, BackendApi invokes this callback so the app
    // can drop back to the anonymous state (which the router redirects to
    // /auth). Registered once for the lifetime of the singleton API.
    BackendApi.instance.onSessionExpired = handleSessionExpired;
  }

  SessionStatus _status = SessionStatus.loading;
  bool _onboardingComplete = false;
  bool _goalSetupComplete = false;

  SessionStatus get status => _status;
  bool get onboardingComplete => _onboardingComplete;
  bool get goalSetupComplete => _goalSetupComplete;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('mizan.onboarding.complete') ?? false;
    _goalSetupComplete = prefs.getBool('mizan.goal_setup_complete') ?? false;
    final hasLocalSession = prefs.getBool('mizan.local.session') ?? false;
    if (hasLocalSession) {
      try {
        final state = await BackendApi.instance.bootstrapSession();
        _status =
            state == SessionBootstrapState.restored
                ? SessionStatus.authenticated
                : SessionStatus.anonymous;
        if (_status == SessionStatus.authenticated) {
          // Goal setup is for first-time onboarding. A returning account must
          // reopen the dashboard, even if this flag was never written by an
          // older app version.
          _goalSetupComplete = true;
          await prefs.setBool('mizan.goal_setup_complete', true);
        }
      } catch (_) {
        // [C6] A network failure (offline, DNS, timeout, 5xx) is NOT an auth
        // failure. If we have a valid local session marker, keep the user
        // authenticated so cached/offline-capable parts of the app can open.
        // The session will be re-verified when connectivity returns.
        _status = SessionStatus.authenticated;
        _goalSetupComplete = true;
        await prefs.setBool('mizan.goal_setup_complete', true);
      }
    } else {
      _status = SessionStatus.anonymous;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mizan.onboarding.complete', true);
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<void> completeGoalSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mizan.goal_setup_complete', true);
    _goalSetupComplete = true;
    notifyListeners();
  }

  void markAuthenticated() {
    _status = SessionStatus.authenticated;
    // A fresh session was just established via login/register - re-arm the
    // API's one-shot expiry guard so a later expiry can notify again.
    BackendApi.instance.resetSessionExpiredFlag();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('mizan.local.session', true),
    );
    // Startup may have attempted FCM registration before login completed.
    unawaited(PushNotificationService.instance.syncAfterAuthentication());
    notifyListeners();
  }

  /// Invoked by [BackendApi] when the session can no longer be refreshed.
  /// Clears the persisted local-session marker and drops to the anonymous
  /// state; the app router then redirects the user to the auth screen. Safe to
  /// call when already anonymous (no-op).
  ///
  /// [M14] Sets the one-time `sessionExpiryProvider` flag so the shell can
  /// show a single "Your session has ended" message. Concurrent 401s are
  /// collapsed by BackendApi's `_sessionExpiredNotified` guard, so this runs
  /// exactly once per real expiry. Manual logout and network-only failures do
  /// NOT call this method.
  Future<void> handleSessionExpired() async {
    if (_status == SessionStatus.anonymous) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mizan.local.session');
    _status = SessionStatus.anonymous;
    await _clearUserScopedState();
    notifyListeners();
    // Raise the one-time UI signal after state is cleared.
    try {
      _expiryRef?.notifyExpired();
    } catch (_) {
      // Provider may not be mounted in some startup contexts; never crash.
    }
  }

  /// Optional reference set by the shell so the controller can raise the
  /// one-time session-expiry signal without a global BuildContext hack.
  SessionExpiryNotifier? _expiryRef;

  void attachExpiryNotifier(SessionExpiryNotifier notifier) {
    _expiryRef = notifier;
  }

  Future<void> signOut() async {
    try {
      await BackendApi.instance.revokeSessionOnServer();
    } catch (_) {}
    await BackendApi.instance.clearSessionState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mizan.local.session');
    _status = SessionStatus.anonymous;
    await _clearUserScopedState();
    notifyListeners();
  }

  /// Clears ALL user-scoped local state so a different account can never see
  /// the previous user's data, even for one frame. Device-level preferences
  /// (theme, onboarding, generic settings) are intentionally preserved.
  Future<void> _clearUserScopedState() async {
    // Clear any user-scoped SharedPreferences keys that stores may write.
    final prefs = await SharedPreferences.getInstance();

    // ActStore's persisted local acts.
    await prefs.remove('mizan.local_acts');
    // Family jar selection (user-scoped).
    await BackendApi.instance.clearAccountSnapshot();

    // Close all WebSocket connections (user-scoped channels).
    WebSocketService.instance.disconnect();

    // Clear the offline action queue — its items belong to the signed-out user.
    await OfflineActionQueue.instance.clearForLogout();

    // A saved last-family-jar is user-specific; BackendApi handles this.
    await BackendApi.instance.saveLastFamilyJarId(null);

    // [Phase 7] Reset push-token lifecycle: cancel the token-refresh
    // subscription and clear the device ID so the previous user's token is
    // never re-registered and the next account starts fresh.
    await PushNotificationService.instance.resetForLogout();
  }
}
