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

  static ActionType fromString(String value) {
    switch (value) {
      case 'add_jar_star':
        return ActionType.addJarStar;
      case 'add_family_act':
        return ActionType.addFamilyAct;
      case 'create_reflection':
        return ActionType.createReflection;
      default:
        throw ArgumentError('Unknown action type: $value');
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

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'] as String,
      actionType: ActionTypeExtension.fromString(json['action_type'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: QueueStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueueStatus.pending,
      ),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      lastError: json['last_error'] as String?,
    );
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
    return rows.map(OfflineQueueItem.fromJson).toList();
  }

  Future<void> updateStatus(String id, QueueStatus status, {String? error}) async {
    await _ensureInitialized();
    await _db!.update(
      'offline_queue',
      {
        'status': status.name,
        'retry_count': status == QueueStatus.failed
            ? 'retry_count + 1'
            : 'retry_count',
        'last_error': error,
      },
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
    await _db!.delete('offline_queue', where: 'status = ?', whereArgs: [QueueStatus.synced.name]);
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
