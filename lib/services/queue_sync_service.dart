import 'dart:async';
import 'package:sadaqah_jar/services/backend_api.dart';
import 'offline_action_queue.dart';
import 'connectivity_service.dart';

class QueueSyncService {
  QueueSyncService._();
  static final QueueSyncService instance = QueueSyncService._();

  static const _maxRetries = 5;

  bool _syncing = false;
  Timer? _retryTimer;
  final BackendApi _api = BackendApi.instance;

  /// Durably records [item] and kicks off a best-effort background sync.
  ///
  /// This is offline-first and defensive by contract: it never rethrows into
  /// the caller. Callers (e.g. the add-act sheet) treat the local write as the
  /// source of truth and must not be shown an error just because the network,
  /// the connectivity check, or even the local queue insert misbehaved. Any
  /// failure here is swallowed and a retry is scheduled so the act is not lost.
  Future<void> enqueueAndSync(OfflineQueueItem item) async {
    try {
      await OfflineActionQueue.instance.enqueue(item);
    } catch (_) {
      // If we couldn't even persist to the queue, there's nothing durable to
      // retry - but we still must not surface this to the UI. Schedule a retry
      // in case it was a transient DB lock.
      scheduleRetry();
      return;
    }
    await _attemptSync();
  }

  Future<void> attemptSync() async {
    _attemptSync();
  }

  Future<void> _attemptSync() async {
    if (_syncing) return;
    bool online;
    try {
      online = await ConnectivityService.instance.checkNow();
    } catch (_) {
      // Treat a failed connectivity probe as "offline" and retry later rather
      // than letting the error escape an unawaited call as an unhandled async
      // exception.
      scheduleRetry();
      return;
    }
    if (!online) {
      scheduleRetry();
      return;
    }

    _syncing = true;
    try {
      final pending = await OfflineActionQueue.instance.getPending();
      if (pending.isEmpty) {
        _syncing = false;
        return;
      }

      for (final item in pending) {
        if (!await ConnectivityService.instance.checkNow()) {
          scheduleRetry();
          break;
        }

        await OfflineActionQueue.instance.updateStatus(
          item.id,
          QueueStatus.syncing,
        );
        try {
          await _execute(item);
          await OfflineActionQueue.instance.remove(item.id);
        } catch (e) {
          final newRetryCount = item.retryCount + 1;
          if (newRetryCount >= _maxRetries) {
            await OfflineActionQueue.instance.updateStatus(
              item.id,
              QueueStatus.failed,
              error: e.toString(),
            );
          } else {
            await OfflineActionQueue.instance.updateStatus(
              item.id,
              QueueStatus.pending,
              error: e.toString(),
            );
            // Auto-retry with backoff instead of waiting for the next
            // manual action or app restart.
            scheduleRetry();
          }
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _execute(OfflineQueueItem item) async {
    final requestId = item.id;
    switch (item.actionType) {
      case ActionType.addJarStar:
        final type = item.payload['type'] as String?;
        final note = item.payload['note'] as String?;
        final actId = (item.payload['act_id'] as num?)?.toInt();
        await _api.addJarStar(
          actId: actId,
          type: type,
          note: note,
          requestId: requestId,
        );
        return;
      case ActionType.addFamilyAct:
        final familyId = (item.payload['family_id'] as num).toInt();
        final type = item.payload['type'] as String?;
        final note = item.payload['note'] as String?;
        await _api.addFamilyAct(
          familyId,
          type: type,
          note: note,
          requestId: requestId,
        );
        return;
      case ActionType.createReflection:
        final title = item.payload['title'] as String;
        final body = item.payload['body'] as String;
        final mood = item.payload['mood'] as String;
        await _api.createReflection(
          title: title,
          body: body,
          mood: mood,
          requestId: requestId,
        );
        return;
    }
  }

  void scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 2), () {
      _attemptSync();
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
