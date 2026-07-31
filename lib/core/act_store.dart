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
  int get today => _acts.where((act) {
    final stamp = DateTime.tryParse(act['created_at']?.toString() ?? '');
    final now = DateTime.now();
    return stamp != null && stamp.year == now.year && stamp.month == now.month && stamp.day == now.day;
  }).length;

  int get totalStars => _goalActsDone ?? _jarCurrentStars ?? _acts.length;

  int get remainingActs {
    final capacity = _goalTarget ?? _jarCapacity;
    final done = _goalActsDone ?? _jarCurrentStars;
    if (capacity == null || done == null) return 0;
    return (capacity - done).clamp(0, capacity);
  }

  double get progress {
    final capacity = _goalTarget ?? _jarCapacity;
    final done = _goalActsDone ?? _jarCurrentStars;
    if (done == null || capacity == null || capacity == 0) return 0.0;
    return (done / capacity).clamp(0.0, 1.0);
  }

  int? _jarCurrentStars;
  int? _jarCapacity;
  int? _goalActsDone;
  int? _goalTarget;
  String? _goalTitle;
  int? _currentStreak;

  int? get currentStreak => _currentStreak;
  String? get goalTitle => _goalTitle;

  Future<void> _refreshJarProgress() async {
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
      final month = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final goals = await BackendApi.instance.getGoals(status: 'active', month: month);
      final goalList = goals['goals'] as List? ?? [];
      if (goalList.isNotEmpty) {
        final firstGoal = goalList.first as Map<String, dynamic>;
        _goalActsDone = (firstGoal['acts_done'] as num?)?.toInt() ?? _jarCurrentStars;
        _goalTarget = (firstGoal['acts_target'] as num?)?.toInt() ?? _jarCapacity;
        _goalTitle = firstGoal['title']?.toString();
      } else {
        _goalActsDone = null;
        _goalTarget = null;
        _goalTitle = null;
      }
    } catch (_) {
      _goalActsDone = null;
      _goalTarget = null;
      _goalTitle = null;
    }
    try {
      final streak = await BackendApi.instance.getStreak();
      _currentStreak = streak.currentStreak;
    } catch (_) {
      _currentStreak = null;
    }
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final values = jsonDecode(raw) as List<dynamic>;
        _acts
          ..clear()
          ..addAll(values.map((value) => Map<String, dynamic>.from(value as Map)));
      } catch (_) {}
    }
    _loaded = true;
    _refreshJarProgress();
  }

  Future<void> add({required String type, String? note}) async {
    _acts.insert(0, {'type': type, 'note': note ?? '', 'created_at': DateTime.now().toIso8601String()});
    if (_acts.length > 250) _acts.removeRange(250, _acts.length);
    notifyListeners();
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_acts));
    }).catchError((_) {});
    await _writeQueue;
    await _refreshJarProgress();
  }
}

final actStoreProvider = ChangeNotifierProvider<ActStore>((ref) {
  final store = ActStore();
  store.load();
  return store;
});
