import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../features/journey/quran/quran_data.dart';

const quranDownloadTaskName = 'mizan.quran.offline.download';
const quranDownloadUniqueName = 'mizan-quran-offline-dataset-v3';

@pragma('vm:entry-point')
void quranDownloadCallbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      DartPluginRegistrant.ensureInitialized();
      if (taskName != quranDownloadTaskName) return true;
      final repository = QuranRepository.instance;
      final subscription = repository.downloadStatus.listen((status) async {
        await repository.persistDownloadStatus(status);
        await Workmanager().reportProgress({
          'completed': status.completed,
          'total': status.total,
          'progress': status.progress,
          'status': status.state.name,
        });
      });
      try {
        await repository.ensureOfflineDataset();
        return true;
      } catch (error) {
        debugPrint('Quran background download failed: $error');
        return false;
      } finally {
        await subscription.cancel();
      }
    },
    onTaskStopped: (taskName, stopReason) async {
      if (taskName != quranDownloadTaskName) return;
      final repository = QuranRepository.instance;
      final current = await repository.loadDownloadStatus();
      await repository.persistDownloadStatus(
        QuranDownloadStatus(
          state: QuranDownloadState.paused,
          completed: current.completed,
          total: current.total,
          message: 'Download paused by Android. Your progress is safely kept.',
        ),
      );
    },
  );
}

class QuranDownloadService {
  QuranDownloadService._();

  static final instance = QuranDownloadService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    await Workmanager().initialize(quranDownloadCallbackDispatcher);
    Workmanager().setProgressListener((uniqueName, progress) {
      if (uniqueName != quranDownloadUniqueName) return;
      unawaited(QuranRepository.instance.refreshPersistedDownloadStatus());
    });
    _initialized = true;
  }

  Future<void> reconcile() async {
    if (kIsWeb) return;
    await initialize();
    final status = await QuranRepository.instance.loadDownloadStatus();
    if (status.state == QuranDownloadState.downloading ||
        status.state == QuranDownloadState.queued ||
        status.state == QuranDownloadState.waitingForNetwork) {
      await enqueue();
    } else {
      QuranRepository.instance.emitDownloadStatus(status);
    }
  }

  Future<void> enqueue() async {
    if (kIsWeb) {
      await QuranRepository.instance.ensureOfflineDataset();
      return;
    }
    await initialize();
    final current = await QuranRepository.instance.loadDownloadStatus();
    if (current.state == QuranDownloadState.complete) return;
    final queued = QuranDownloadStatus(
      state: QuranDownloadState.queued,
      completed: current.completed,
      total: current.total,
      message: 'Quran download queued',
    );
    await QuranRepository.instance.persistDownloadStatus(queued);
    QuranRepository.instance.emitDownloadStatus(queued);
    try {
      await Workmanager().registerOneOffTask(
        quranDownloadUniqueName,
        quranDownloadTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresStorageNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        foregroundServiceConfig: ForegroundServiceConfig(
          notificationTitle: 'Preparing the Quran for offline reading',
          notificationText:
              'Mizan will keep your download safe in the background',
          notificationChannelId: 'mizan_quran_downloads',
          notificationChannelName: 'Quran downloads',
          notificationId: 2401,
        ),
      );
    } catch (error) {
      final failed = QuranDownloadStatus(
        state: QuranDownloadState.failed,
        completed: current.completed,
        total: current.total,
        message: 'The Quran download could not be started. Tap retry.',
      );
      await QuranRepository.instance.persistDownloadStatus(failed);
      QuranRepository.instance.emitDownloadStatus(failed);
      debugPrint('Quran download queue failed: $error');
      rethrow;
    }
  }

  Future<void> cancel() async {
    if (!kIsWeb) {
      await Workmanager().cancelByUniqueName(quranDownloadUniqueName);
    }
    final current = await QuranRepository.instance.loadDownloadStatus();
    final cancelled = QuranDownloadStatus(
      state: QuranDownloadState.cancelled,
      completed: current.completed,
      total: current.total,
      message: 'Download cancelled. Your completed files were kept.',
    );
    await QuranRepository.instance.persistDownloadStatus(cancelled);
    QuranRepository.instance.emitDownloadStatus(cancelled);
  }
}
