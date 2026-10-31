import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/analytics/events.dart';
import '../core/analytics/values.dart';
import '../core/engine/audio_engine.dart';
import '../core/library/library_repository.dart';
import '../core/rules/personalization.dart';
import '../core/rules/ringtone_rules.dart';
import '../features/paywall/checkout.dart';
import 'analytics_sync.dart';
import 'config.dart';
import 'state.dart';

enum BatchItemStatus { waiting, converting, done, failed }

class BatchItem {
  const BatchItem({
    required this.source,
    this.status = BatchItemStatus.waiting,
    this.fraction = 0,
    this.output,
    this.error,
  });

  final SourceFile source;
  final BatchItemStatus status;
  final double fraction;
  final LibraryItem? output;
  final EngineErrorCode? error;

  BatchItem copyWith({
    BatchItemStatus? status,
    double? fraction,
    LibraryItem? output,
    EngineErrorCode? error,
  }) {
    return BatchItem(
      source: source,
      status: status ?? this.status,
      fraction: fraction ?? this.fraction,
      output: output ?? this.output,
      error: status == BatchItemStatus.waiting ? null : error ?? this.error,
    );
  }
}

/// Localised copy the controller needs for system UI outside the app.
class BatchCopy {
  const BatchCopy({
    required this.backgroundTitle,
    required this.progress,
    required this.doneTitle,
    required this.doneBody,
  });

  final String backgroundTitle;
  final String Function(int done, int total) progress;
  final String doneTitle;
  final String Function(int done) doneBody;
}

class BatchState {
  const BatchState({
    required this.id,
    required this.items,
    required this.format,
    required this.quality,
    required this.startedAt,
    this.running = false,
    this.paused = false,
    this.stopped = false,
    this.continued = false,
    this.backgrounded = false,
  });

  final String id;
  final List<BatchItem> items;
  final OutFormat format;
  final Quality quality;
  final DateTime startedAt;
  final bool running;

  /// iOS 16–25 suspended the app; resumes from the next file on return.
  final bool paused;
  final bool stopped;

  /// iOS 26 continued processing accepted the batch.
  final bool continued;
  final bool backgrounded;

  int get total => items.length;
  int get done => items.where((i) => i.status == BatchItemStatus.done).length;
  int get failed =>
      items.where((i) => i.status == BatchItemStatus.failed).length;
  bool get finished => !running && !paused;

  /// 0–1 across all files, counting the current file's progress.
  double get fraction {
    if (items.isEmpty) return 0;
    final current = items
        .where((i) => i.status == BatchItemStatus.converting)
        .fold<double>(0, (sum, i) => sum + i.fraction);
    return ((done + failed + current) / total).clamp(0, 1);
  }

  BatchState copyWith({
    List<BatchItem>? items,
    bool? running,
    bool? paused,
    bool? stopped,
    bool? continued,
    bool? backgrounded,
  }) {
    return BatchState(
      id: id,
      items: items ?? this.items,
      format: format,
      quality: quality,
      startedAt: startedAt,
      running: running ?? this.running,
      paused: paused ?? this.paused,
      stopped: stopped ?? this.stopped,
      continued: continued ?? this.continued,
      backgrounded: backgrounded ?? this.backgrounded,
    );
  }
}

/// Batch (21): Pro, up to `batchMaxFiles`, sequential. One failure never
/// stops the queue and finished files are saved immediately (`05` §6, §9).
class BatchController extends Notifier<BatchState?> {
  StreamSubscription<ProgressEvent>? _progress;
  String? _currentJob;
  BatchCopy? _copy;
  bool _looping = false;

  @override
  BatchState? build() {
    ref.onDispose(() => _progress?.cancel());
    return null;
  }

  bool get isRunning => state?.running ?? false;

  bool get _inBackground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle != null && lifecycle != AppLifecycleState.resumed;
  }

  Future<void> start(List<SourceFile> sources, BatchCopy copy) async {
    if (isRunning || sources.isEmpty) return;
    final max = ref.read(appConfigProvider).batchMaxFiles;
    final prefs = ref.read(preferencesProvider);
    _copy = copy;
    state = BatchState(
      id: 'batch-${DateTime.now().microsecondsSinceEpoch}',
      items: [for (final s in sources.take(max)) BatchItem(source: s)],
      format: prefs.defaultFormat,
      quality:
          Quality.values
              .where((q) => q.kbps == prefs.defaultKbps)
              .firstOrNull ??
          Quality.high,
      startedAt: DateTime.now(),
      running: true,
    );
    final engine = ref.read(audioEngineProvider);
    ref
        .read(analyticsProvider)
        .batchStarted(
          count: state!.total,
          format: AnalyticsValues.format(prefs.defaultFormat),
        );
    final continued = await engine.startContinuedBatch(copy.backgroundTitle);
    state = state?.copyWith(continued: continued);
    unawaited(_loop());
  }

  /// S4 "Retry failed (n)".
  Future<void> retryFailed() async {
    final current = state;
    if (current == null || current.running || current.failed == 0) return;
    state = current.copyWith(
      running: true,
      stopped: false,
      items: [
        for (final item in current.items)
          item.status == BatchItemStatus.failed
              ? item.copyWith(status: BatchItemStatus.waiting, fraction: 0)
              : item,
      ],
    );
    final copy = _copy;
    if (copy != null) {
      final continued = await ref
          .read(audioEngineProvider)
          .startContinuedBatch(copy.backgroundTitle);
      state = state?.copyWith(continued: continued);
    }
    unawaited(_loop());
  }

  /// Call when the app returns to the foreground.
  void resumeIfPaused() {
    final current = state;
    if (current == null || !current.paused) return;
    ref.read(analyticsProvider).jobResumed(task: 'batch');
    state = current.copyWith(paused: false, running: true);
    unawaited(_loop());
  }

  Future<void> stop() async {
    final current = state;
    if (current == null || !current.running) return;
    state = current.copyWith(stopped: true);
    final job = _currentJob;
    if (job != null) await ref.read(audioEngineProvider).cancel(job);
  }

  void sendToBackground() {
    final current = state;
    if (current != null) state = current.copyWith(backgrounded: true);
  }

  void clear() {
    if (!isRunning) state = null;
  }

  @visibleForTesting
  set debugState(BatchState value) => state = value;

  Future<void> _loop() async {
    if (_looping) return;
    _looping = true;
    try {
      while (true) {
        final current = state;
        if (current == null || current.stopped || current.paused) break;
        final index = current.items.indexWhere(
          (i) => i.status == BatchItemStatus.waiting,
        );
        if (index < 0) break;
        await _convert(index);
      }
    } finally {
      _looping = false;
    }
    final current = state;
    if (current == null || current.paused) return;
    state = current.copyWith(running: false);
    await _finish();
  }

  void _setItem(int index, BatchItem Function(BatchItem item) change) {
    final current = state;
    if (current == null) return;
    final items = [...current.items];
    items[index] = change(items[index]);
    state = current.copyWith(items: items);
  }

  Future<void> _convert(int index) async {
    final batch = state!;
    final engine = ref.read(audioEngineProvider);
    final config = ref.read(appConfigProvider);
    final source = batch.items[index].source;
    final id = '${batch.id}-$index-${DateTime.now().millisecondsSinceEpoch}';
    final started = DateTime.now();
    final draft = ConvertDraft(
      source: source,
      mode: ConvertMode.audioFile,
      format: batch.format,
      quality: batch.quality,
      tone: ToneType.ringtone,
      start: 0,
      end: source.info.durationSec,
      fadeIn: false,
      fadeOut: false,
      boost: false,
    );
    _currentJob = id;
    _setItem(
      index,
      (i) => i.copyWith(status: BatchItemStatus.converting, fraction: 0),
    );
    await _progress?.cancel();
    _progress = engine.progress(id).listen((event) {
      _setItem(index, (i) => i.copyWith(fraction: event.fraction));
    });
    try {
      if (!source.info.hasAudio || source.info.isProtected) {
        throw EngineException(
          source.info.isProtected
              ? EngineErrorCode.protected
              : EngineErrorCode.noAudio,
        );
      }
      final result = await engine.convert(id, buildRequest(draft, config));
      if (!File(result.outputPath).existsSync()) {
        throw const EngineException(EngineErrorCode.io);
      }
      await ref.read(usageStoreProvider).recordSuccess(ringtone: false);
      final item = await saveToLibrary(
        ref,
        id: id,
        draft: draft,
        result: result,
        started: started,
      );
      _setItem(
        index,
        (i) =>
            i.copyWith(status: BatchItemStatus.done, fraction: 1, output: item),
      );
    } on EngineException catch (error) {
      final current = state;
      final interrupted = error.code == EngineErrorCode.interrupted;
      if (current != null && current.stopped) {
        _setItem(
          index,
          (i) => i.copyWith(status: BatchItemStatus.waiting, fraction: 0),
        );
      } else if (interrupted &&
          current != null &&
          !current.continued &&
          _inBackground) {
        // iOS 16–25: the app was suspended. Pause; this file runs again.
        // TODO(phase 10): persist a paused batch as "Paused" in My files with
        // Resume (05 §9) so it survives the app being closed.
        _setItem(
          index,
          (i) => i.copyWith(status: BatchItemStatus.waiting, fraction: 0),
        );
        state = state?.copyWith(paused: true);
        final info = await engine.appInfo();
        final paused = state;
        ref
            .read(analyticsProvider)
            .backgroundInterrupted(
              task: 'batch',
              progressPct: ((paused?.fraction ?? 0) * 100).round(),
              iosMajor: osMajor(info),
            );
      } else {
        _setItem(
          index,
          (i) => i.copyWith(status: BatchItemStatus.failed, error: error.code),
        );
      }
    } finally {
      _currentJob = null;
      await _progress?.cancel();
      _progress = null;
      final current = state;
      final copy = _copy;
      if (current != null && copy != null && current.continued) {
        await engine.updateContinuedBatch(
          current.done + current.failed,
          current.total,
          copy.progress(current.done, current.total),
        );
      }
    }
  }

  Future<void> _finish() async {
    final current = state;
    if (current == null) return;
    final engine = ref.read(audioEngineProvider);
    ref
        .read(analyticsProvider)
        .batchCompleted(
          count: current.total,
          failedCount: current.failed,
          secondsTaken:
              DateTime.now().difference(current.startedAt).inMilliseconds /
              1000,
        );
    unawaited(ref.read(analyticsSyncProvider).updateTotals());
    if (current.continued) {
      await engine.finishContinuedBatch(success: current.failed == 0);
      state = current.copyWith(continued: false);
    }
    final copy = _copy;
    if (copy != null && _inBackground && !current.stopped && current.done > 0) {
      await ref
          .read(trialReminderProvider)
          .notifyBatchDone(
            title: copy.doneTitle,
            body: copy.doneBody(current.done),
          );
    }
  }
}

final batchProvider = NotifierProvider<BatchController, BatchState?>(
  BatchController.new,
);
