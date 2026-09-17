import 'dart:async';
import 'package:sadaqah_jar/services/backend_api.dart';
import 'offline_action_queue.dart';
import 'connectivity_service.dart';

class QueueSyncService {
  QueueSyncService._();
  static final QueueSyncService instance = QueueSyncService._();

  bool _syncing = false;
  Timer? _retryTimer;
  final BackendApi _api = BackendApi.instance;

  /// Durably records [item] and kicks off a best-effort background sync.
  ///
  /// This is offline-first by contract: the durable local write completes
  /// before any network work begins. Network failures are handled by the
  /// background retry path; storage failures are returned to the caller so a
  /// screen cannot claim an action was saved when the outbox was unavailable.
  Future<void> enqueueAndSync(OfflineQueueItem item) async {
    // The local write is the completion point for an offline-first action.
    // Let storage errors reach the caller because claiming success when the
    // outbox could not be written would lose the user's action.
    try {
      await OfflineActionQueue.instance.enqueue(item);
    } catch (_) {
      scheduleRetry();
      rethrow;
    }
    unawaited(_attemptSyncSafely());
  }

  Future<void> _attemptSyncSafely() async {
    try {
      await _attemptSync();
    } catch (_) {
      // A transient database/network failure must not become an unhandled
      // Future error. The persisted item remains available for retry.
      scheduleRetry();
    }
  }

  Future<void> attemptSync() => _attemptSync();

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
          final errorMessage = e.toString();
          if (newRetryCount >= OfflineActionQueue.maxRetries) {
            await OfflineActionQueue.instance.updateStatus(
              item.id,
              QueueStatus.failed,
              error: errorMessage,
            );
          } else {
            // Record the failed attempt before returning to pending. This
            // keeps retry limits meaningful across app restarts.
            await OfflineActionQueue.instance.updateStatus(
              item.id,
              QueueStatus.failed,
              error: errorMessage,
            );
            await OfflineActionQueue.instance.updateStatus(
              item.id,
              QueueStatus.pending,
              error: errorMessage,
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
        final isPrivate = item.payload['is_private'] as bool? ?? false;
        await _api.createReflection(
          title: title,
          body: body,
          mood: mood,
          isPrivate: isPrivate,
          requestId: requestId,
        );
        return;
      case ActionType.archiveNotification:
        final notificationId =
            (item.payload['notification_id'] as num).toInt();
        await _api.deleteNotification(notificationId);
        return;
    }
  }

  void scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 2), () {
      unawaited(_attemptSyncSafely());
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
