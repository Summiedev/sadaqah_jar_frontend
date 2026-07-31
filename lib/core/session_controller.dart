import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_api.dart';

enum SessionStatus { loading, anonymous, authenticated }

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final session = SessionController();
  session.restore();
  return session;
});

class SessionController extends ChangeNotifier {
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
        _status = state == SessionBootstrapState.restored
            ? SessionStatus.authenticated
            : SessionStatus.anonymous;
      } catch (_) {
        _status = SessionStatus.anonymous;
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
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('mizan.local.session', true));
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await BackendApi.instance.revokeSessionOnServer();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mizan.local.session');
    _status = SessionStatus.anonymous;
    notifyListeners();
  }
}