import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_api.dart';

class ActStore extends ChangeNotifier {
  static const _key = 'mizan.local_acts';
  final List<Map<String, dynamic>> _acts = [];
  bool _loaded = false;
  Future<void> _writeQueue = Future<void>.value();

  bool get loaded => _loaded;
  int get total => _acts.length;
  int get today =>
      _acts.where((act) {
        final stamp = DateTime.tryParse(act['created_at']?.toString() ?? '');
        final now = DateTime.now();
        return stamp != null &&
            stamp.year == now.year &&
            stamp.month == now.month &&
            stamp.day == now.day;
      }).length;

  // Acts added locally that the backend has not yet confirmed. This makes the
  // jar fill move the instant a user adds an act - online or offline - instead
  // of waiting for a round-trip that may still be queued. It is reconciled back
  // toward zero in [_refreshJarProgress] as the server count catches up.
  int _optimisticDelta = 0;
  int? _lastKnownDone;

  int get totalStars {
    final base = _goalActsDone ?? _jarCurrentStars;
    // When we have no backend baseline yet, the local list already counts the
    // new act, so we must NOT also add the optimistic delta (double counting).
    if (base == null) return _acts.length;
    return base + _optimisticDelta;
  }

  int get remainingActs {
    final capacity = _goalTarget ?? _jarCapacity;
    final done = _goalActsDone ?? _jarCurrentStars;
    if (capacity == null || done == null) return 0;
    return (capacity - (done + _optimisticDelta)).clamp(0, capacity);
  }

  double get progress {
    final capacity = _goalTarget ?? _jarCapacity;
    final done = _goalActsDone ?? _jarCurrentStars;
    if (done == null || capacity == null || capacity == 0) return 0.0;
    return ((done + _optimisticDelta) / capacity).clamp(0.0, 1.0);
  }

  int? _jarCurrentStars;
  int? _jarCapacity;
  int? _goalActsDone;
  int? _goalTarget;
  String? _goalTitle;
  String? _goalSubtitle;
  int? _goalId;
  int? _currentStreak;
  bool _streakError = false;

  int? get currentStreak => _currentStreak;
  bool get streakError => _streakError;
  String? get goalTitle => _goalTitle;
  String? get goalSubtitle => _goalSubtitle;
  int? get goalId => _goalId;
  int? get goalTarget => _goalTarget ?? _jarCapacity;

  Future<void>? _jarRefreshFuture;

  /// Single-flight refresh: concurrent callers share one in-flight request.
  /// A stale response can never overwrite a newer one because each generation
  /// begins only after the previous call fully completes.
  Future<void> _refreshJarProgress() {
    return _jarRefreshFuture ??= _doRefreshJarProgress().whenComplete(() {
      _jarRefreshFuture = null;
    });
  }

  Future<void> _doRefreshJarProgress() async {
    try {
      final jar = await BackendApi.instance.getJar();
      _jarCurrentStars = jar.currentStars;
      _jarCapacity = jar.capacity;
    } catch (_) {
      _jarCurrentStars = null;
      _jarCapacity = null;
    }
    try {
      final now = DateTime.now();
      final month =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final goals = await BackendApi.instance.getGoals(
        status: 'active',
        month: month,
      );
      final goalList = goals['goals'] as List? ?? [];
      if (goalList.isNotEmpty) {
        final firstGoal = goalList.first as Map<String, dynamic>;
        _goalId = (firstGoal['id'] as num?)?.toInt();
        _goalActsDone =
            (firstGoal['acts_done'] as num?)?.toInt() ?? _jarCurrentStars;
        _goalTarget =
            (firstGoal['acts_target'] as num?)?.toInt() ?? _jarCapacity;
        _goalTitle = firstGoal['title']?.toString();
        _goalSubtitle = firstGoal['subtitle']?.toString();
      } else {
        _goalId = null;
        _goalActsDone = null;
        _goalTarget = null;
        _goalTitle = null;
        _goalSubtitle = null;
      }
    } catch (_) {
      _goalId = null;
      _goalActsDone = null;
      _goalTarget = null;
      _goalTitle = null;
      _goalSubtitle = null;
    }
    _reconcileOptimisticDelta();

    try {
      final streak = await BackendApi.instance.getStreak();
      _currentStreak = streak.currentStreak;
      _streakError = false;
    } catch (_) {
      _currentStreak = null;
      _streakError = true;
    }
    notifyListeners();
  }

  Future<void> retryStreak() async {
    _streakError = false;
    notifyListeners();
    await _refreshJarProgress();
  }

  /// Shrinks the optimistic delta once the server count catches up with what we
  /// already showed. The jar fill therefore never jumps backward: it only ever
  /// moves forward, and the delta is gradually paid down as sync confirms acts.
  void _reconcileOptimisticDelta() {
    if (_optimisticDelta <= 0) return;
    final confirmed = _goalActsDone ?? _jarCurrentStars;
    if (confirmed == null) return;
    if (_lastKnownDone != null && confirmed <= _lastKnownDone!) {
      // Server hasn't moved yet (queued act not synced) - keep the delta.
      _lastKnownDone = confirmed;
      return;
    }
    final consumed = confirmed - (_lastKnownDone ?? confirmed);
    if (consumed > 0) {
      _optimisticDelta = (_optimisticDelta - consumed).clamp(0, 1 << 30);
    }
    _lastKnownDone = confirmed;
  }

  void _insertLocalAct({required String type, String? note}) {
    _acts.insert(0, {
      'type': type,
      'note': note ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
    if (_acts.length > 250) _acts.removeRange(250, _acts.length);
  }

  Future<void> _persistLocalActs() async {
    _writeQueue = _writeQueue
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_key, jsonEncode(_acts));
        })
        .catchError((_) {});
    await _writeQueue;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // The same provider instance can survive logout and be reused after the
    // next login. Always clear the previous account's in-memory acts before
    // reading the current local cache and refreshing server-backed progress.
    _acts.clear();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final values = jsonDecode(raw) as List<dynamic>;
        _acts
          ..clear()
          ..addAll(
            values.map((value) => Map<String, dynamic>.from(value as Map)),
          );
      } catch (_) {}
    }
    _loaded = true;
    // Do not publish the initial widget/UI state until the account-backed jar,
    // goal and streak values have been restored.
    await _refreshJarProgress();
  }

  Future<void> add({required String type, String? note}) async {
    _insertLocalAct(type: type, note: note);

    // Optimistically move the jar fill forward immediately. We only do this once
    // we already have a backend baseline (otherwise totalStars falls back to the
    // local list length and would double count). Seed _lastKnownDone so the next
    // refresh can tell whether the server has caught up with this act yet.
    if ((_goalActsDone ?? _jarCurrentStars) != null) {
      _lastKnownDone ??= _goalActsDone ?? _jarCurrentStars;
      _optimisticDelta += 1;
    }
    notifyListeners();

    await _persistLocalActs();

    // Fire-and-forget refresh so the UI is never blocked on network calls.
    // The local act already counts; the server state will reconcile in the
    // background regardless of connectivity.
    unawaited(_refreshJarProgress());
  }

  Future<void> addRemote({
    required String type,
    String? note,
    String? requestId,
  }) async {
    _lastKnownDone ??= _goalActsDone ?? _jarCurrentStars;
    _optimisticDelta += 1;
    notifyListeners();
    try {
      await BackendApi.instance.addJarStar(
        type: type,
        note: note,
        requestId: requestId,
      );
      _insertLocalAct(type: type, note: note);
      await _persistLocalActs();
      await _refreshJarProgress();
    } catch (_) {
      _optimisticDelta = (_optimisticDelta - 1).clamp(0, 1 << 30);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal({
    required String title,
    String? subtitle,
    required int actsTarget,
  }) async {
    final id = _goalId;
    if (id == null) {
      // Phase 24 (M8): Do NOT fabricate a timestamp as a real backend goal ID.
      // Create the goal through the API and store the real returned ID.
      try {
        final created = await BackendApi.instance.createGoal(
          title: title,
          subtitle: subtitle,
          actsTarget: actsTarget,
        );
        _goalId = (created['id'] as num?)?.toInt();
        _goalTitle = title;
        _goalSubtitle = subtitle;
        _goalTarget = actsTarget;
        notifyListeners();
        await _refreshJarProgress();
        return;
      } catch (_) {
        rethrow;
      }
    }
    try {
      await BackendApi.instance.updateGoal(
        goalId: id,
        title: title,
        subtitle: subtitle,
        actsTarget: actsTarget,
      );
    } catch (_) {
      rethrow;
    }
    _goalTitle = title;
    _goalSubtitle = subtitle;
    _goalTarget = actsTarget;
    notifyListeners();
    await _refreshJarProgress();
  }

  /// Clears ALL user-scoped state so a different account can never see the
  /// previous user's data, even for one frame. This intentionally does NOT
  /// touch device-level preferences such as theme or onboarding completion.
  Future<void> resetForLogout() async {
    _acts.clear();
    _optimisticDelta = 0;
    _lastKnownDone = null;
    _jarCurrentStars = null;
    _jarCapacity = null;
    _goalActsDone = null;
    _goalTarget = null;
    _goalTitle = null;
    _goalSubtitle = null;
    _goalId = null;
    _currentStreak = null;
    _streakError = false;
    _loaded = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
}

final actStoreProvider = ChangeNotifierProvider<ActStore>((ref) {
  final store = ActStore();
  store.load();
  return store;
});
