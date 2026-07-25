import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_api.dart';

enum SessionStatus { loading, anonymous, authenticated }

class SessionController extends ChangeNotifier {
  SessionStatus _status = SessionStatus.loading;
  bool _onboardingComplete = false;

  SessionStatus get status => _status;
  bool get onboardingComplete => _onboardingComplete;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('mizan.onboarding.complete') ?? false;
    _status = (prefs.getBool('mizan.local.session') ?? false)
        ? SessionStatus.authenticated
        : SessionStatus.anonymous;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mizan.onboarding.complete', true);
    _onboardingComplete = true;
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
