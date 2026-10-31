import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely_engine/tunely_engine.dart';
import 'package:tunely_engine/tunely_engine.dart' as native show progress;

export 'package:tunely_engine/tunely_engine.dart'
    show
        AppInfo,
        ConvertRequest,
        ConvertResult,
        MediaInfo,
        OutFormat,
        ProgressEvent;

/// Typed failures from the native engine. Screens map them per `05` §6.
enum EngineErrorCode {
  unreadable,
  noAudio,
  protected,
  icloud,
  noSpace,
  interrupted,
  cancelled,
  decode,
  encode,
  io,
  staleBookmark,
  unavailable,
  unknown;

  static EngineErrorCode fromWire(String code) {
    return switch (code) {
      'unreadable' => unreadable,
      'no_audio' => noAudio,
      'protected' => protected,
      'icloud' => icloud,
      'no_space' => noSpace,
      'interrupted' => interrupted,
      'cancelled' => cancelled,
      'decode' => decode,
      'encode' => encode,
      'io' => io,
      'stale_bookmark' => staleBookmark,
      'unavailable' => unavailable,
      _ => unknown,
    };
  }
}

class EngineException implements Exception {
  const EngineException(this.code, [this.message]);

  final EngineErrorCode code;
  final String? message;

  @override
  String toString() => 'EngineException(${code.name})';
}

/// App-facing engine. Native code only runs jobs; rules stay in `lib/core/rules/`.
abstract class AudioEngine {
  Future<List<String>> pickVideos({int maxCount = 1});
  Future<MediaInfo> inspect(String path);
  Future<List<double>> waveform(String path, {int buckets = 48});
  Future<String?> thumbnail(String path, {int maxPixels = 300});
  Future<ConvertResult> convert(String jobId, ConvertRequest request);
  Future<void> cancel(String jobId);
  Stream<ProgressEvent> progress(String jobId);
  Future<Set<OutFormat>> availableFormats();
  Future<String?> pickFolder();
  Future<String?> bookmarkedFolderName(String bookmarkId);
  Future<bool> bookmarkedFolderIsICloud(String bookmarkId);
  Future<String> copyToBookmarkedFolder(String path, String bookmarkId);
  Future<int> freeBytes();
  Future<void> cleanTemp({int olderThanHours = 24});
  Future<bool> openUrl(String url);
  Future<AppInfo> appInfo();

  /// iOS 26 continued processing for batch and long merges. False elsewhere.
  Future<bool> startContinuedBatch(String title);
  Future<void> updateContinuedBatch(int completed, int total, String subtitle);
  Future<void> finishContinuedBatch({required bool success});

  /// ATT status: notDetermined, restricted, denied, authorized.
  Future<String> trackingStatus();
  Future<String> requestTracking();

  /// SKStoreProductViewController; false when the page can't load.
  Future<bool> openAppStorePage(String appStoreId);

  /// DeviceCheck token; null where unsupported.
  Future<String?> deviceCheckToken();
}

class PigeonAudioEngine implements AudioEngine {
  PigeonAudioEngine({EngineApi? api}) : _api = api ?? EngineApi();

  final EngineApi _api;
  Stream<ProgressEvent>? _events;

  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw EngineException(
        EngineErrorCode.fromWire(error.code),
        error.message,
      );
    }
  }

  @override
  Future<List<String>> pickVideos({int maxCount = 1}) =>
      _call(() => _api.pickVideos(maxCount));

  @override
  Future<MediaInfo> inspect(String path) => _call(() => _api.inspect(path));

  @override
  Future<List<double>> waveform(String path, {int buckets = 48}) =>
      _call(() => _api.waveform(path, buckets));

  @override
  Future<String?> thumbnail(String path, {int maxPixels = 300}) =>
      _call(() => _api.thumbnail(path, maxPixels));

  @override
  Future<ConvertResult> convert(String jobId, ConvertRequest request) =>
      _call(() => _api.convert(jobId, request));

  @override
  Future<void> cancel(String jobId) => _call(() => _api.cancel(jobId));

  @override
  Stream<ProgressEvent> progress(String jobId) {
    final events = _events ??= native.progress().asBroadcastStream();
    return events.where((event) => event.jobId == jobId);
  }

  @override
  Future<Set<OutFormat>> availableFormats() async =>
      (await _call(_api.availableFormats)).toSet();

  @override
  Future<String?> pickFolder() => _call(_api.pickFolder);

  @override
  Future<String?> bookmarkedFolderName(String bookmarkId) =>
      _call(() => _api.bookmarkedFolderName(bookmarkId));

  @override
  Future<bool> bookmarkedFolderIsICloud(String bookmarkId) =>
      _call(() => _api.bookmarkedFolderIsICloud(bookmarkId));

  @override
  Future<String> copyToBookmarkedFolder(String path, String bookmarkId) =>
      _call(() => _api.copyToBookmarkedFolder(path, bookmarkId));

  @override
  Future<int> freeBytes() => _call(_api.freeBytes);

  @override
  Future<void> cleanTemp({int olderThanHours = 24}) =>
      _call(() => _api.cleanTemp(olderThanHours));

  @override
  Future<bool> openUrl(String url) => _call(() => _api.openUrl(url));

  @override
  Future<AppInfo> appInfo() => _call(_api.appInfo);

  @override
  Future<bool> startContinuedBatch(String title) =>
      _call(() => _api.startContinuedBatch(title));

  @override
  Future<void> updateContinuedBatch(
    int completed,
    int total,
    String subtitle,
  ) => _call(() => _api.updateContinuedBatch(completed, total, subtitle));

  @override
  Future<void> finishContinuedBatch({required bool success}) =>
      _call(() => _api.finishContinuedBatch(success));

  @override
  Future<String> trackingStatus() => _call(_api.trackingStatus);

  @override
  Future<String> requestTracking() => _call(_api.requestTracking);

  @override
  Future<String?> deviceCheckToken() => _call(_api.deviceCheckToken);

  @override
  Future<bool> openAppStorePage(String appStoreId) =>
      _call(() => _api.openAppStorePage(appStoreId));
}

/// iOS major version from [AppInfo.osVersion], e.g. 26 or 18.
int osMajor(AppInfo info) => int.tryParse(info.osVersion.split('.').first) ?? 0;

final audioEngineProvider = Provider<AudioEngine>((ref) => PigeonAudioEngine());
