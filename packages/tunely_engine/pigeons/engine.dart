// Pigeon contract from `docs/handoff/06_Technical_Architecture.md`.
// Regenerate with: dart run pigeon --input pigeons/engine.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/engine_api.g.dart',
    swiftOut: 'ios/Classes/EngineApi.g.swift',
    kotlinOut:
        'android/src/main/kotlin/com/mbxtunely/tunely_engine/EngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.mbxtunely.tunely_engine'),
    dartPackageName: 'tunely_engine',
  ),
)
enum OutFormat { mp3, m4a, wav, m4r, flac, aac, ogg }

class MediaInfo {
  MediaInfo({
    required this.path,
    required this.bytes,
    required this.durationSec,
    required this.hasAudio,
    required this.isProtected,
    required this.isLocal,
    required this.sampleRate,
    required this.channels,
    required this.container,
    required this.hasVideo,
    this.sourceBitrate,
    this.variableFrameRate,
  });

  String path;
  int bytes;
  double durationSec;
  bool hasAudio;
  bool hasVideo;
  bool isProtected;
  bool isLocal;

  /// Kilobits per second of the source audio track, when known.
  int? sourceBitrate;
  int sampleRate;
  int channels;
  String container;

  /// Video whose frame rate varies (screen recordings, some cameras).
  bool? variableFrameRate;
}

class ConvertRequest {
  ConvertRequest({
    required this.inputs,
    required this.format,
    required this.bitrateKbps,
    required this.startSec,
    required this.endSec,
    required this.fadeInSec,
    required this.fadeOutSec,
    required this.gainDb,
    required this.crossfadeSec,
    required this.outputName,
    this.sampleRate,
    this.compatibilityMode,
  });

  /// E1 retry: export with AVAssetExportSession (Apple M4A) first, then transcode.
  bool? compatibilityMode;

  /// One path converts; two or more merge in list order.
  List<String> inputs;
  OutFormat format;
  int bitrateKbps;
  int? sampleRate;

  /// Trim range of a single input. `endSec <= 0` means the end of the file.
  double startSec;
  double endSec;
  double fadeInSec;
  double fadeOutSec;
  double gainDb;
  double crossfadeSec;

  /// File name without extension. The engine adds the extension and
  /// resolves duplicates with " 2", " 3".
  String outputName;
}

class ConvertResult {
  ConvertResult({
    required this.jobId,
    required this.outputPath,
    required this.outputBytes,
    required this.seconds,
  });

  String jobId;
  String outputPath;
  int outputBytes;

  /// Length of the output audio in seconds.
  double seconds;
}

class AppInfo {
  AppInfo({
    required this.version,
    required this.build,
    required this.osVersion,
  });

  String version;
  String build;

  /// e.g. "26.0" or "18.5".
  String osVersion;
}

class ProgressEvent {
  ProgressEvent({required this.jobId, required this.fraction});

  String jobId;
  double fraction;
}

/// Errors are thrown as platform errors with one of these codes:
/// unreadable, no_audio, protected, icloud, no_space, interrupted, cancelled,
/// decode, encode, io, stale_bookmark, unavailable, unknown.
@HostApi()
abstract class EngineApi {
  /// PHPicker without Photos permission. Returns temp copies.
  @async
  List<String> pickVideos(int maxCount);

  @async
  MediaInfo inspect(String path);

  /// Peak values 0..1, cached per file.
  @async
  List<double> waveform(String path, int buckets);

  /// JPEG frame of a video, cached per file. Null for audio-only files.
  @async
  String? thumbnail(String path, int maxPixels);

  @async
  ConvertResult convert(String jobId, ConvertRequest request);

  void cancel(String jobId);

  /// Formats whose encoder is bundled in this build.
  List<OutFormat> availableFormats();

  /// Folder picker. Returns a bookmark id, or null when cancelled.
  @async
  String? pickFolder();

  /// Display name of the bookmarked folder, or null when it can't be resolved.
  String? bookmarkedFolderName(String bookmarkId);

  /// Whether the bookmarked folder lives in iCloud Drive (analytics only).
  bool bookmarkedFolderIsICloud(String bookmarkId);

  /// Copies into the bookmarked folder and returns the new file name.
  @async
  String copyToBookmarkedFolder(String path, String bookmarkId);

  int freeBytes();

  void cleanTemp(int olderThanHours);

  /// iOS 26 continued processing. False when unsupported.
  @async
  bool startContinuedBatch(String title);

  /// Updates the system progress UI of the continued batch.
  void updateContinuedBatch(int completed, int total, String subtitle);

  void finishContinuedBatch(bool success);

  /// Opens mailto:, https:, or `app-settings:`. False when nothing can open it.
  @async
  bool openUrl(String url);

  AppInfo appInfo();

  /// App Tracking Transparency: notDetermined, restricted, denied, authorized.
  String trackingStatus();

  /// Shows the system ATT prompt (only once per install by iOS).
  @async
  String requestTracking();

  /// Apple DeviceCheck token (base64) for one-redemption-per-iPhone; null
  /// where DeviceCheck is unavailable (simulator).
  @async
  String? deviceCheckToken();

  /// App Store product page inside the app (SKStoreProductViewController).
  @async
  bool openAppStorePage(String appStoreId);
}

@EventChannelApi()
abstract class EngineEvents {
  ProgressEvent progress();
}
