import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum QueueStatus { pending, syncing, failed, synced }

/// Changes whenever the durable offline outbox changes.
///
/// Screens that render optimistic local activity can listen to this instead
/// of waiting for a restart or a manual refresh after an action is queued or
/// synchronized.
final ValueNotifier<int> offlineQueueRevision = ValueNotifier<int>(0);

enum ActionType {
  addJarStar,
  addFamilyAct,
  createReflection,
  archiveNotification,
}

extension ActionTypeExtension on ActionType {
  String get value {
    switch (this) {
      case ActionType.addJarStar:
        return 'add_jar_star';
      case ActionType.addFamilyAct:
        return 'add_family_act';
      case ActionType.createReflection:
        return 'create_reflection';
      case ActionType.archiveNotification:
        return 'archive_notification';
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
      case 'archive_notification':
        return ActionType.archiveNotification;
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
    Map<String, dynamic> payload;
    try {
      final decoded =
          payloadRaw is String ? jsonDecode(payloadRaw) : payloadRaw;
      if (decoded is! Map) return null;
      payload = Map<String, dynamic>.from(decoded);
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
      'payload': jsonEncode(payload),
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

  static const maxRetries = 5;

  Database? _db;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_queue.db');
    _db = await openDatabase(
      path,
      version: 2,
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // A killed process must not leave work permanently marked as
          // syncing. The remote APIs are idempotent via the queue item id.
          await db.update(
            'offline_queue',
            {'status': QueueStatus.pending.name},
            where: 'status = ?',
            whereArgs: [QueueStatus.syncing.name],
          );
        }
      },
    );
    // A process can be killed without changing the database schema. Recover
    // rows that were being sent so the next launch can safely retry them.
    await _db!.update(
      'offline_queue',
      {'status': QueueStatus.pending.name},
      where: 'status = ?',
      whereArgs: [QueueStatus.syncing.name],
    );
    _initialized = true;
  }

  Future<void> enqueue(OfflineQueueItem item) async {
    await _ensureInitialized();
    // A retry or a rapid double tap must not create a second logical action.
    await _db!.insert(
      'offline_queue',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    offlineQueueRevision.value++;
  }

  Future<List<OfflineQueueItem>> getPending() async {
    return _readItems(
      where: 'status = ? OR (status = ? AND retry_count < ?)',
      whereArgs: [
        QueueStatus.pending.name,
        QueueStatus.failed.name,
        maxRetries,
      ],
    );
  }

  /// Returns unfinished actions, including a currently syncing action. This
  /// is used to restore optimistic local UI after a process restart.
  Future<List<OfflineQueueItem>> getUnfinished({ActionType? actionType}) async {
    return _readItems(
      where:
          actionType == null
              ? 'status IN (?, ?, ?)'
              : 'action_type = ? AND status IN (?, ?, ?)',
      whereArgs:
          actionType == null
              ? [
                QueueStatus.pending.name,
                QueueStatus.syncing.name,
                QueueStatus.failed.name,
              ]
              : [
                actionType.value,
                QueueStatus.pending.name,
                QueueStatus.syncing.name,
                QueueStatus.failed.name,
              ],
    );
  }

  Future<List<OfflineQueueItem>> _readItems({
    required String where,
    required List<Object?> whereArgs,
  }) async {
    await _ensureInitialized();
    final rows = await _db!.query(
      'offline_queue',
      where: where,
      whereArgs: whereArgs,
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
    offlineQueueRevision.value++;
  }

  Future<void> remove(String id) async {
    await _ensureInitialized();
    await _db!.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
    offlineQueueRevision.value++;
  }

  Future<int> getPendingCount() async {
    await _ensureInitialized();
    final result = await _db!.rawQuery(
      "SELECT COUNT(*) as count FROM offline_queue "
      "WHERE status = ? OR (status = ? AND retry_count < ?)",
      [QueueStatus.pending.name, QueueStatus.failed.name, maxRetries],
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
    offlineQueueRevision.value++;
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
