import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/audio_engine.dart';
import '../core/format.dart';
import '../core/library/app_database.dart';
import '../core/library/app_paths.dart';
import '../core/library/library_repository.dart';
import '../core/library/preferences_store.dart';
import '../core/library/usage_store.dart';
import '../core/rules/free_limit.dart';
import '../core/rules/merge_rules.dart';
import '../core/rules/personalization.dart';
import '../core/rules/preflight.dart';
import '../core/rules/ringtone_rules.dart';
import '../core/rules/size_estimator.dart';
import 'config.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/events.dart';
import '../core/analytics/values.dart';
import 'account.dart';
import 'ads.dart';
import 'analytics_sync.dart';
import 'monetization.dart';

T _mustOverride<T>(String name) =>
    throw StateError('$name must be overridden at startup.');

final appPathsProvider = Provider<AppPaths>((_) => _mustOverride('appPaths'));
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => _mustOverride('appDatabase'),
);
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(appPathsProvider),
  ),
);
final usageStoreProvider = Provider<UsageStore>(
  (ref) => UsageStore(ref.watch(appDatabaseProvider)),
);

/// Loaded in `main` so the counter is right on the first frame.
final initialFreeLimitProvider = Provider<FreeLimitSnapshot>(
  (_) => _mustOverride('initialFreeLimit'),
);

/// Entitlement "pro" (StoreKit). Pro hides every free-tier element.
final isProProvider = Provider<bool>(
  (ref) => ref.watch(entitlementProvider).isPro,
);

final preferencesStoreProvider = Provider<PreferencesStore>(
  (_) => _mustOverride('preferencesStore'),
);

/// Onboarding answers and Settings defaults. Changes apply immediately.
class PreferencesController extends Notifier<UserPrefs> {
  @override
  UserPrefs build() => ref.watch(preferencesStoreProvider).read();

  Future<void> _save(UserPrefs next) async {
    state = next;
    await ref.read(preferencesStoreProvider).write(next);
  }

  Future<void> setGoal(UserGoal goal) => _save(state.copyWith(goal: goal));

  Future<void> setFrequency(UsageFrequency frequency) =>
      _save(state.copyWith(frequency: frequency));

  Future<void> setDefaultFormat(OutFormat format, int kbps) =>
      _save(state.copyWith(defaultFormat: format, defaultKbps: kbps));

  Future<void> rememberFormat(OutFormat format) =>
      _save(state.copyWith(lastFormat: format));

  Future<void> completeOnboarding() =>
      _save(state.copyWith(onboardingDone: true));
}

final preferencesProvider = NotifierProvider<PreferencesController, UserPrefs>(
  PreferencesController.new,
);

final personalizationProvider = Provider<Personalization>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return Personalization(goal: prefs.goal, frequency: prefs.frequency);
});

final appInfoProvider = FutureProvider<AppInfo>(
  (ref) => ref.watch(audioEngineProvider).appInfo(),
);

class FreeLimitController extends Notifier<FreeLimitSnapshot> {
  @override
  FreeLimitSnapshot build() => ref.watch(initialFreeLimitProvider);

  int get total => ref.read(appConfigProvider).freeConversionsPerDay;

  int get remaining =>
      math.max(0, total + state.rewardedToday - state.usedToday);

  /// Call on launch and whenever the app returns to the foreground.
  Future<void> refresh([DateTime? now]) async {
    final next = FreeLimit.reconcile(state, now ?? DateTime.now());
    if (!identical(next, state)) {
      state = next;
      await ref.read(usageStoreProvider).writeFreeLimit(next);
    }
  }

  /// Rewarded ad reward callback (P3 "Watch a short ad for 1 more").
  Future<void> addRewarded() async {
    await refresh();
    state = FreeLimit.recordRewarded(state);
    await ref.read(usageStoreProvider).writeFreeLimit(state);
  }

  Future<void> recordFinished({
    required bool success,
    required bool outputExists,
    bool isNewConversion = true,
  }) async {
    await refresh();
    final next = FreeLimit.recordFinished(
      state,
      success: success,
      outputExists: outputExists,
      isNewConversion: isNewConversion,
    );
    if (!identical(next, state)) {
      state = next;
      await ref.read(usageStoreProvider).writeFreeLimit(next);
    }
  }
}

final freeLimitProvider =
    NotifierProvider<FreeLimitController, FreeLimitSnapshot>(
      FreeLimitController.new,
    );

final recentItemsProvider = StreamProvider<List<LibraryItem>>((ref) async* {
  final repo = ref.watch(libraryRepositoryProvider);
  yield await repo.list(limit: 2);
  await for (final _ in repo.changes) {
    yield await repo.list(limit: 2);
  }
});

final libraryItemsProvider = StreamProvider<List<LibraryItem>>((ref) async* {
  final repo = ref.watch(libraryRepositoryProvider);
  yield await repo.list();
  await for (final _ in repo.changes) {
    yield await repo.list();
  }
});

/// A file chosen in the picker, inspected once.
class SourceFile {
  const SourceFile({
    required this.path,
    required this.name,
    required this.info,
    this.thumbnailPath,
  });

  final String path;
  final String name;
  final MediaInfo info;
  final String? thumbnailPath;

  bool get isVideo => info.hasVideo;
}

/// Videos and audio files picked in this session, newest first.
class PickedSources extends Notifier<List<SourceFile>> {
  @override
  List<SourceFile> build() => const [];

  void add(SourceFile source) {
    state = [source, ...state.where((s) => s.path != source.path)];
  }
}

final pickedSourcesProvider = NotifierProvider<PickedSources, List<SourceFile>>(
  PickedSources.new,
);

enum Quality { standard, high, best }

extension QualityBitrate on Quality {
  int get kbps => switch (this) {
    Quality.standard => 128,
    Quality.high => 256,
    Quality.best => 320,
  };

  AudioPreset get preset => switch (this) {
    Quality.standard => AudioPreset.standard,
    Quality.high => AudioPreset.high,
    Quality.best => AudioPreset.best,
  };
}

extension OutFormatRules on OutFormat {
  bool get isLossless => this == OutFormat.wav || this == OutFormat.flac;

  bool get isPro => ProGate.requires(format: _outputFormat);

  OutputFormat get _outputFormat => OutputFormat.values.byName(name);

  String get label => name.toUpperCase();
}

/// Everything the Convert, Trim and Converting screens agree on.
class ConvertDraft {
  const ConvertDraft({
    required this.source,
    required this.mode,
    required this.format,
    required this.quality,
    required this.tone,
    required this.start,
    required this.end,
    required this.fadeIn,
    required this.fadeOut,
    required this.boost,
    this.peaks = const [],
    this.mergeWith = const [],
    this.crossfadeSec = 0,
    this.outputName,
  });

  /// The first input. For a merge, [mergeWith] holds the rest in order.
  final SourceFile source;
  final ConvertMode mode;
  final OutFormat format;
  final Quality quality;
  final ToneType tone;
  final double start;
  final double end;
  final bool fadeIn;
  final bool fadeOut;
  final bool boost;
  final List<double> peaks;
  final List<SourceFile> mergeWith;
  final int crossfadeSec;

  /// Output base name; defaults to the source name.
  final String? outputName;

  bool get isMerge => mergeWith.isNotEmpty;
  List<SourceFile> get inputs => [source, ...mergeWith];

  double get sourceSeconds => isMerge
      ? MergeRules.totalSeconds([
          for (final s in inputs) s.info.durationSec,
        ], crossfadeSec)
      : source.info.durationSec;
  double get seconds => math.max(0, end - start);
  bool get isRingtone => mode == ConvertMode.ringtone;
  bool get isTrimmed => start > 0.05 || end < sourceSeconds - 0.05;
  OutFormat get outputFormat => isRingtone ? OutFormat.m4r : format;

  int get bitrateKbps =>
      isRingtone ? 128 : (format.isLossless ? 0 : quality.kbps);

  AudioPreset get preset {
    if (isRingtone) return AudioPreset.ringtone;
    return switch (format) {
      OutFormat.wav => AudioPreset.wav,
      OutFormat.flac => AudioPreset.flac,
      _ => quality.preset,
    };
  }

  bool get requestsPro => ProGate.requires(
    format: OutputFormat.values.byName(outputFormat.name),
    tone: isRingtone ? tone : null,
    volumeBoost: boost,
  );

  SizeEstimate estimate({AudioPreset? preset}) => SizeEstimator.estimate(
    preset: preset ?? this.preset,
    seconds: seconds.round(),
    sourceBitrateKbps: source.info.sourceBitrate,
  );

  ConvertDraft copyWith({
    ConvertMode? mode,
    OutFormat? format,
    Quality? quality,
    ToneType? tone,
    double? start,
    double? end,
    bool? fadeIn,
    bool? fadeOut,
    bool? boost,
    List<double>? peaks,
  }) {
    return ConvertDraft(
      source: source,
      mergeWith: mergeWith,
      crossfadeSec: crossfadeSec,
      outputName: outputName,
      mode: mode ?? this.mode,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      tone: tone ?? this.tone,
      start: start ?? this.start,
      end: end ?? this.end,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
      boost: boost ?? this.boost,
      peaks: peaks ?? this.peaks,
    );
  }
}

class DraftController extends Notifier<ConvertDraft?> {
  @override
  ConvertDraft? build() => null;

  void start(SourceFile source, {ConvertMode? mode}) {
    final personal = ref.read(personalizationProvider);
    final prefs = ref.read(preferencesProvider);
    final chosen = mode ?? personal.convertMode;
    final format = personal.goal == UserGoal.convertFiles
        ? prefs.lastFormat ?? prefs.defaultFormat
        : personal.defaultPreset != null
        ? OutFormat.mp3
        : prefs.defaultFormat;
    final quality =
        Quality.values.where((q) => q.kbps == prefs.defaultKbps).firstOrNull ??
        Quality.high;
    state = _forMode(
      ConvertDraft(
        source: source,
        mode: chosen,
        format: format,
        quality: personal.defaultPreset != null ? Quality.high : quality,
        tone: ToneType.ringtone,
        start: 0,
        end: source.info.durationSec,
        fadeIn: false,
        fadeOut: false,
        boost: false,
      ),
      chosen,
    );
  }

  /// A prepared draft (Merge).
  void set(ConvertDraft draft) => state = draft;

  void update(ConvertDraft Function(ConvertDraft draft) change) {
    final draft = state;
    if (draft != null) state = change(draft);
  }

  void setMode(ConvertMode mode) {
    final draft = state;
    if (draft != null && draft.mode != mode) state = _forMode(draft, mode);
  }

  void setTone(ToneType tone) {
    final draft = state;
    if (draft == null) return;
    state = _ringtoneSelection(draft.copyWith(tone: tone));
  }

  void setPeaks(List<double> peaks) {
    final draft = state;
    if (draft == null) return;
    final next = draft.copyWith(peaks: peaks);
    state = next.isRingtone && !next.isTrimmed
        ? _ringtoneSelection(next)
        : next;
  }

  ConvertDraft _forMode(ConvertDraft draft, ConvertMode mode) {
    if (mode == ConvertMode.audioFile) {
      return draft.copyWith(
        mode: mode,
        start: 0,
        end: draft.sourceSeconds,
        fadeIn: false,
        fadeOut: false,
      );
    }
    return _ringtoneSelection(
      draft.copyWith(mode: mode, fadeIn: true, fadeOut: true),
    );
  }

  ConvertDraft _ringtoneSelection(ConvertDraft draft) {
    final config = ref.read(appConfigProvider);
    final selection = RingtoneRules.defaultSelection(
      duration: Duration(milliseconds: (draft.sourceSeconds * 1000).round()),
      peaks: draft.peaks,
      type: draft.tone,
      config: config,
    );
    return draft.copyWith(
      start: selection.start.inMilliseconds / 1000,
      end: selection.end.inMilliseconds / 1000,
    );
  }
}

final draftProvider = NotifierProvider<DraftController, ConvertDraft?>(
  DraftController.new,
);

enum JobStatus { running, succeeded, failed }

class JobState {
  const JobState({
    required this.id,
    required this.draft,
    required this.status,
    required this.fraction,
    required this.startedAt,
    this.item,
    this.error,
    this.backgrounded = false,
    this.compatibility = false,
  });

  final String id;
  final ConvertDraft draft;
  final JobStatus status;
  final double fraction;
  final DateTime startedAt;
  final LibraryItem? item;
  final EngineErrorCode? error;

  /// The user left the Converting screen with "Run in background".
  final bool backgrounded;

  /// E1 retry through Apple's exporter.
  final bool compatibility;

  JobState copyWith({
    JobStatus? status,
    double? fraction,
    LibraryItem? item,
    EngineErrorCode? error,
    bool? backgrounded,
  }) {
    return JobState(
      id: id,
      draft: draft,
      status: status ?? this.status,
      fraction: fraction ?? this.fraction,
      startedAt: startedAt,
      item: item ?? this.item,
      error: error ?? this.error,
      backgrounded: backgrounded ?? this.backgrounded,
      compatibility: compatibility,
    );
  }
}

/// Runs one conversion. Counts a free use only after the file exists.
class JobController extends Notifier<JobState?> {
  StreamSubscription<ProgressEvent>? _progress;

  @override
  JobState? build() {
    ref.onDispose(() => _progress?.cancel());
    return null;
  }

  bool get isRunning => state?.status == JobStatus.running;

  Future<void> start(ConvertDraft draft, {bool compatibility = false}) async {
    if (isRunning) return;
    final engine = ref.read(audioEngineProvider);
    final config = ref.read(appConfigProvider);
    ref.read(paywallProvider.notifier).noteTask();
    final id = 'job-${DateTime.now().microsecondsSinceEpoch}';
    final started = DateTime.now();
    state = JobState(
      id: id,
      draft: draft,
      status: JobStatus.running,
      fraction: 0,
      startedAt: started,
      compatibility: compatibility,
    );
    await _progress?.cancel();
    _progress = engine.progress(id).listen((event) {
      final current = state;
      if (current != null &&
          current.id == id &&
          current.status == JobStatus.running) {
        state = current.copyWith(fraction: event.fraction);
      }
    });

    final request = buildRequest(draft, config, compatibility: compatibility);
    final analytics = ref.read(analyticsProvider);
    final task = draft.isMerge
        ? 'merge'
        : draft.isRingtone
        ? 'ringtone'
        : 'convert';
    final format = AnalyticsValues.format(draft.outputFormat);
    final quality = draft.quality.name;
    final mode = AnalyticsValues.mode(draft.mode);
    analytics.taskStarted(
      task: task,
      format: format,
      quality: quality,
      mode: mode,
      inputType: draft.source.isVideo ? 'video' : 'audio',
      durationS: draft.seconds,
      estSizeMb: mb(draft.estimate().bytes),
    );
    if (draft.isMerge) {
      analytics.mergeStarted(
        count: draft.inputs.length,
        crossfadeS: draft.crossfadeSec,
        format: format,
      );
    }

    try {
      final result = await engine.convert(id, request);
      final exists = File(result.outputPath).existsSync();
      if (!draft.isMerge) {
        await ref
            .read(freeLimitProvider.notifier)
            .recordFinished(success: true, outputExists: exists);
      }
      if (!exists) throw const EngineException(EngineErrorCode.io);
      await ref
          .read(usageStoreProvider)
          .recordSuccess(ringtone: draft.isRingtone);
      if (!draft.isRingtone && !draft.isMerge) {
        await ref
            .read(preferencesProvider.notifier)
            .rememberFormat(draft.format);
      }
      if (!draft.isMerge) await ref.read(adsProvider.notifier).noteConversion();
      final item = await saveToLibrary(
        ref,
        id: id,
        draft: draft,
        result: result,
        started: started,
      );
      state = state?.copyWith(
        status: JobStatus.succeeded,
        fraction: 1,
        item: item,
      );
      final took = DateTime.now().difference(started).inMilliseconds / 1000;
      final freeLimit = ref.read(freeLimitProvider.notifier);
      analytics.taskCompleted(
        task: task,
        format: format,
        quality: quality,
        mode: mode,
        sizeMb: mb(result.outputBytes),
        secondsTaken: took,
        durationS: result.seconds,
        freeLeft: ref.read(isProProvider) ? null : freeLimit.remaining,
      );
      if (draft.isRingtone) {
        final fade = config.fadeDefaultSeconds;
        analytics.ringtoneCreated(
          toneType: AnalyticsValues.toneType(draft.tone),
          lengthS: result.seconds,
          fadeInS: draft.fadeIn ? fade : 0,
          fadeOutS: draft.fadeOut ? fade : 0,
        );
      }
      if (draft.isMerge) {
        analytics.mergeCompleted(
          count: draft.inputs.length,
          lengthS: result.seconds,
          secondsTaken: took,
        );
      }
      unawaited(ref.read(analyticsSyncProvider).updateTotals());
      unawaited(ref.read(referralProvider.notifier).qualifyIfNeeded());
    } on EngineException catch (error) {
      final progress = ((state?.fraction ?? 0) * 100).round();
      state = state?.copyWith(status: JobStatus.failed, error: error.code);
      switch (error.code) {
        case EngineErrorCode.cancelled:
          break; // task_cancelled is sent when Stop is confirmed.
        case EngineErrorCode.interrupted:
          final info = await engine.appInfo();
          analytics.backgroundInterrupted(
            task: draft.isMerge ? 'merge' : 'single',
            progressPct: progress,
            iosMajor: osMajor(info),
          );
          analytics.taskFailed(
            task: task,
            errorType: 'interrupted',
            progressPct: progress,
            format: format,
          );
        default:
          final vfr = draft.source.info.variableFrameRate ?? false;
          analytics.taskFailed(
            task: task,
            errorType: vfr && error.code != EngineErrorCode.io
                ? 'vfr'
                : AnalyticsValues.errorType(error.code),
            progressPct: progress,
            format: format,
          );
      }
    } finally {
      await _progress?.cancel();
      _progress = null;
    }
  }

  Future<void> cancel() async {
    final current = state;
    if (current == null || current.status != JobStatus.running) return;
    await ref.read(audioEngineProvider).cancel(current.id);
  }

  void sendToBackground() {
    final current = state;
    if (current != null && current.status == JobStatus.running) {
      state = current.copyWith(backgrounded: true);
    }
  }

  void clear() {
    if (!isRunning) state = null;
  }
}

/// The engine request for a draft (single file, trimmed, merged).
ConvertRequest buildRequest(
  ConvertDraft draft,
  AppConfig config, {
  bool compatibility = false,
}) {
  final fade = config.fadeDefaultSeconds.toDouble();
  final base = draft.outputName ?? Fmt.baseName(draft.source.name);
  return ConvertRequest(
    inputs: [for (final input in draft.inputs) input.path],
    format: draft.outputFormat,
    bitrateKbps: draft.bitrateKbps,
    sampleRate: draft.quality == Quality.best && !draft.isRingtone
        ? math.min(48000, math.max(44100, draft.source.info.sampleRate))
        : null,
    startSec: draft.isTrimmed ? draft.start : 0,
    endSec: draft.isTrimmed ? draft.end : 0,
    fadeInSec: draft.fadeIn ? fade : 0,
    fadeOutSec: draft.fadeOut ? fade : 0,
    gainDb: draft.boost ? config.volumeBoostMaxDb.toDouble() : 0,
    crossfadeSec: draft.crossfadeSec.toDouble(),
    compatibilityMode: compatibility,
    outputName: draft.isRingtone
        ? RingtoneRules.fileName(base).replaceAll(RegExp(r'\.m4r$'), '')
        : base,
  );
}

/// Copies the thumbnail and records the output in My files.
Future<LibraryItem> saveToLibrary(
  Ref ref, {
  required String id,
  required ConvertDraft draft,
  required ConvertResult result,
  required DateTime started,
}) async {
  final paths = ref.read(appPathsProvider);
  String? thumbRel;
  final thumb = draft.source.thumbnailPath;
  if (thumb != null && File(thumb).existsSync()) {
    final target = File('${paths.thumbnails}/$id.jpg');
    await target.parent.create(recursive: true);
    await File(thumb).copy(target.path);
    thumbRel = paths.containerRelative(target.path);
  }
  final item = LibraryItem(
    id: id,
    relPath: paths.relative(result.outputPath),
    name: result.outputPath.split('/').last,
    format: draft.outputFormat.name,
    bitrateKbps: draft.bitrateKbps,
    bytes: result.outputBytes,
    durationSec: result.seconds,
    toneType: draft.isRingtone ? draft.tone : null,
    sourceName: draft.source.name,
    sourceBytes: [for (final s in draft.inputs) s.info.bytes]
        .fold(0, (a, b) => a + b),
    sourceIsVideo: draft.source.isVideo,
    tookMs: DateTime.now().difference(started).inMilliseconds,
    thumbRel: thumbRel,
    createdAt: DateTime.now(),
  );
  await ref.read(libraryRepositoryProvider).add(item);
  return item;
}

final jobProvider = NotifierProvider<JobController, JobState?>(
  JobController.new,
);
