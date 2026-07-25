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

  int get totalStars => _jarCurrentStars ?? _acts.length;

  int get remainingActs {
    if (_jarCapacity == null || _jarCurrentStars == null) return 0;
    return (_jarCapacity! - _jarCurrentStars!).clamp(0, _jarCapacity!);
  }

  double get progress {
    if (_jarCurrentStars == null || _jarCapacity == null || _jarCapacity == 0) return 0.0;
    return (_jarCurrentStars! / _jarCapacity!).clamp(0.0, 1.0);
  }

  int? _jarCurrentStars;
  int? _jarCapacity;

  Future<void> _refreshJarProgress() async {
    try {
      final jar = await BackendApi.instance.getJar();
      _jarCurrentStars = jar.currentStars;
      _jarCapacity = jar.capacity;
    } catch (_) {
      _jarCurrentStars = null;
      _jarCapacity = null;
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
    _refreshJarProgress();
  }
}

final actStoreProvider = ChangeNotifierProvider<ActStore>((ref) {
  final store = ActStore();
  store.load();
  return store;
});
