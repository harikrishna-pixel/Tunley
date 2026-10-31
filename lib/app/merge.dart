import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/audio_engine.dart';
import '../core/rules/merge_rules.dart';
import '../core/rules/personalization.dart';
import '../core/rules/ringtone_rules.dart';
import 'config.dart';
import 'state.dart';

class MergeState {
  const MergeState({
    this.files = const [],
    this.crossfadeSec = MergeRules.defaultCrossfade,
    this.format = OutFormat.mp3,
    this.quality = Quality.high,
  });

  final List<SourceFile> files;
  final int crossfadeSec;
  final OutFormat format;
  final Quality quality;

  double get totalSeconds => MergeRules.totalSeconds([
    for (final f in files) f.info.durationSec,
  ], crossfadeSec);

  MergeState copyWith({
    List<SourceFile>? files,
    int? crossfadeSec,
    OutFormat? format,
    Quality? quality,
  }) {
    return MergeState(
      files: files ?? this.files,
      crossfadeSec: crossfadeSec ?? this.crossfadeSec,
      format: format ?? this.format,
      quality: quality ?? this.quality,
    );
  }

  /// The draft the Converting screen runs; null below 2 files.
  ConvertDraft? draft(String outputName) {
    if (files.length < MergeRules.minFiles) return null;
    return ConvertDraft(
      source: files.first,
      mergeWith: files.sublist(1),
      crossfadeSec: crossfadeSec,
      outputName: outputName,
      mode: ConvertMode.audioFile,
      format: format,
      quality: quality,
      tone: ToneType.ringtone,
      start: 0,
      end: totalSeconds,
      fadeIn: false,
      fadeOut: false,
      boost: false,
    );
  }
}

/// Merge (41) list: order = list order, 2–10 files (`05` §11).
class MergeController extends Notifier<MergeState> {
  @override
  MergeState build() {
    final prefs = ref.read(preferencesProvider);
    return MergeState(
      format: prefs.defaultFormat,
      quality:
          Quality.values
              .where((q) => q.kbps == prefs.defaultKbps)
              .firstOrNull ??
          Quality.high,
    );
  }

  int get room => MergeRules.room(
    state.files.length,
    maxFiles: ref.read(appConfigProvider).mergeMaxFiles,
  );

  void reset() => state = build();

  /// Adds files the picker returned, skipping duplicates, up to the cap.
  void add(List<SourceFile> files) {
    final existing = {for (final f in state.files) f.path};
    final fresh = files.where((f) => existing.add(f.path)).take(room);
    state = state.copyWith(files: [...state.files, ...fresh]);
  }

  void remove(int index) {
    state = state.copyWith(files: [...state.files]..removeAt(index));
  }

  /// [newIndex] is the final position (already adjusted for the removal).
  void reorder(int oldIndex, int newIndex) {
    final files = [...state.files];
    final item = files.removeAt(oldIndex);
    files.insert(newIndex.clamp(0, files.length), item);
    state = state.copyWith(files: files);
  }

  void setCrossfade(int seconds) =>
      state = state.copyWith(crossfadeSec: seconds);

  void setFormat(OutFormat format, Quality quality) =>
      state = state.copyWith(format: format, quality: quality);
}

final mergeProvider = NotifierProvider<MergeController, MergeState>(
  MergeController.new,
);
