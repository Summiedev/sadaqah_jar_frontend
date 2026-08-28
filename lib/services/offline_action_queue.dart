import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum QueueStatus { pending, syncing, failed, synced }

enum ActionType { addJarStar, addFamilyAct, createReflection }

extension ActionTypeExtension on ActionType {
  String get value {
    switch (this) {
      case ActionType.addJarStar:
        return 'add_jar_star';
      case ActionType.addFamilyAct:
        return 'add_family_act';
      case ActionType.createReflection:
        return 'create_reflection';
    }
  }

  static ActionType? tryParse(String? value) {
    switch (value) {
      case 'add_jar_star':
        return ActionType.addJarStar;
      case 'add_family_act':
        return ActionType.addFamilyAct;
      case 'create_reflection':
        return ActionType.createReflection;
      default:
        return null;
    }
  }
}

class OfflineQueueItem {
  OfflineQueueItem({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.status = QueueStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final ActionType actionType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  QueueStatus status;
  int retryCount;
  String? lastError;

  /// Safe factory that never throws on a malformed row. If a row is corrupt
  /// (missing id, bad action type, bad date, non-map payload), it returns null
  /// so the caller can quarantine/remove it instead of retrying forever.
  static OfflineQueueItem? tryFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final actionType = ActionTypeExtension.tryParse(
      json['action_type']?.toString(),
    );
    if (actionType == null) return null;

    final payloadRaw = json['payload'];
    if (payloadRaw is! Map) return null;
    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(payloadRaw);
    } catch (_) {
      return null;
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      return null;
    }

    final statusRaw = json['status']?.toString();
    QueueStatus status;
    try {
      status = QueueStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => QueueStatus.pending,
      );
    } catch (_) {
      status = QueueStatus.pending;
    }

    return OfflineQueueItem(
      id: id,
      actionType: actionType,
      payload: payload,
      createdAt: createdAt,
      status: status,
      retryCount:
          (json['retry_count'] is num)
              ? (json['retry_count'] as num).toInt()
              : int.tryParse(json['retry_count']?.toString() ?? '') ?? 0,
      lastError: json['last_error']?.toString(),
    );
  }

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return tryFromJson(json) ??
        (throw FormatException('Invalid OfflineQueueItem row: $json'));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType.value,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }
}

class OfflineActionQueue {
  OfflineActionQueue._();
  static final OfflineActionQueue instance = OfflineActionQueue._();

  Database? _db;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_queue (
            id TEXT PRIMARY KEY,
            action_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
    _initialized = true;
  }

  Future<void> enqueue(OfflineQueueItem item) async {
    await _ensureInitialized();
    await _db!.insert('offline_queue', item.toJson());
  }

  Future<List<OfflineQueueItem>> getPending() async {
    await _ensureInitialized();
    final rows = await _db!.query(
      'offline_queue',
      where: 'status IN (?, ?)',
      whereArgs: [QueueStatus.pending.name, QueueStatus.failed.name],
      orderBy: 'created_at ASC',
    );
    final items = <OfflineQueueItem>[];
    final corruptIds = <String>[];
    for (final row in rows) {
      final item = OfflineQueueItem.tryFromJson(row);
      if (item == null) {
        // Phase 38: quarantine corrupt rows so one bad row can't poison the queue.
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) corruptIds.add(id);
        continue;
      }
      items.add(item);
    }
    if (corruptIds.isNotEmpty) {
      for (final id in corruptIds) {
        try {
          await _db!.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
        } catch (_) {}
      }
    }
    return items;
  }

  Future<void> updateStatus(
    String id,
    QueueStatus status, {
    String? error,
  }) async {
    await _ensureInitialized();
    // H4 fix: read retry_count, increment in Dart, write the integer.
    // Using 'retry_count + 1' as a bound value is a bug - sqflite treats it as
    // a literal, never incrementing the counter and breaking the max-retry cap.
    int newRetry = 0;
    if (status == QueueStatus.failed) {
      final rows = await _db!.query(
        'offline_queue',
        columns: ['retry_count'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final raw = rows.first['retry_count'];
        final parsed =
            raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
        newRetry = parsed + 1;
        if (newRetry < 0) newRetry = 1;
      } else {
        newRetry = 1;
      }
    } else {
      final rows = await _db!.query(
        'offline_queue',
        columns: ['retry_count'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final raw = rows.first['retry_count'];
        newRetry =
            raw is num
                ? raw.toInt()
                : int.tryParse(raw?.toString() ?? '0') ?? 0;
      }
    }
    await _db!.update(
      'offline_queue',
      {'status': status.name, 'retry_count': newRetry, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> remove(String id) async {
    await _ensureInitialized();
    await _db!.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingCount() async {
    await _ensureInitialized();
    final result = await _db!.rawQuery(
      "SELECT COUNT(*) as count FROM offline_queue WHERE status IN (?, ?)",
      [QueueStatus.pending.name, QueueStatus.failed.name],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> clearSynced() async {
    await _ensureInitialized();
    await _db!.delete(
      'offline_queue',
      where: 'status = ?',
      whereArgs: [QueueStatus.synced.name],
    );
  }

  /// Removes every queued item — used on logout so a signed-out user's pending
  /// actions can never be replayed into a different account.
  Future<void> clearForLogout() async {
    await _ensureInitialized();
    await _db!.delete('offline_queue');
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}

final offlineQueueProvider = Provider<OfflineActionQueue>((ref) {
  return OfflineActionQueue.instance;
});

final pendingQueueCountProvider = FutureProvider<int>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.getPendingCount();
});
