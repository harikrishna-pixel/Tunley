import '../../app/config.dart';
import 'ringtone_rules.dart';

enum PreflightBlock {
  unreadable,
  noAudio,
  protected,
  icloud,
  noSpace,
  proFeature,
  freeLimit,
}

enum OutputFormat { mp3, m4a, wav, flac, aac, ogg, m4r }

abstract final class ProGate {
  static bool requires({
    OutputFormat? format,
    ToneType? tone,
    bool volumeBoost = false,
    bool merge = false,
    int fileCount = 1,
  }) {
    final proFormat =
        format == OutputFormat.flac ||
        format == OutputFormat.aac ||
        format == OutputFormat.ogg;
    final proTone = tone == ToneType.alarm || tone == ToneType.textTone;
    return proFormat || proTone || volumeBoost || merge || fileCount >= 2;
  }
}

class PreflightOutcome {
  const PreflightOutcome._({required this.block, this.missingMb})
    : countsConversion = false;

  const PreflightOutcome.ok() : this._(block: null);

  final PreflightBlock? block;
  final int? missingMb;

  /// Pre-flight never consumes a free conversion.
  final bool countsConversion;

  bool get allowed => block == null;
}

class PreflightInput {
  const PreflightInput({
    required this.canOpen,
    required this.hasAudioTrack,
    required this.hasProtectedContent,
    required this.icloudDownloadFailed,
    required this.freeBytes,
    required this.estimateBytes,
    required this.isPro,
    required this.requestsProFeature,
    required this.usedToday,
    required this.rewardedToday,
    required this.config,
  });

  final bool canOpen;
  final bool hasAudioTrack;
  final bool hasProtectedContent;
  final bool icloudDownloadFailed;
  final int freeBytes;
  final int estimateBytes;
  final bool isPro;
  final bool requestsProFeature;
  final int usedToday;
  final int rewardedToday;
  final AppConfig config;

  PreflightInput copyWith({
    bool? canOpen,
    bool? hasAudioTrack,
    bool? hasProtectedContent,
    bool? icloudDownloadFailed,
    int? freeBytes,
    int? estimateBytes,
    bool? isPro,
    bool? requestsProFeature,
    int? usedToday,
    int? rewardedToday,
  }) {
    return PreflightInput(
      canOpen: canOpen ?? this.canOpen,
      hasAudioTrack: hasAudioTrack ?? this.hasAudioTrack,
      hasProtectedContent: hasProtectedContent ?? this.hasProtectedContent,
      icloudDownloadFailed: icloudDownloadFailed ?? this.icloudDownloadFailed,
      freeBytes: freeBytes ?? this.freeBytes,
      estimateBytes: estimateBytes ?? this.estimateBytes,
      isPro: isPro ?? this.isPro,
      requestsProFeature: requestsProFeature ?? this.requestsProFeature,
      usedToday: usedToday ?? this.usedToday,
      rewardedToday: rewardedToday ?? this.rewardedToday,
      config: config,
    );
  }
}

abstract final class Preflight {
  static const int _bytesPerMb = 1024 * 1024;

  static PreflightOutcome check(PreflightInput input) {
    if (!input.canOpen) {
      return const PreflightOutcome._(block: PreflightBlock.unreadable);
    }
    if (!input.hasAudioTrack) {
      return const PreflightOutcome._(block: PreflightBlock.noAudio);
    }
    if (input.hasProtectedContent) {
      return const PreflightOutcome._(block: PreflightBlock.protected);
    }
    if (input.icloudDownloadFailed) {
      return const PreflightOutcome._(block: PreflightBlock.icloud);
    }

    final requiredBytes =
        input.estimateBytes * 2 + input.config.spaceMarginMb * _bytesPerMb;
    if (input.freeBytes < requiredBytes) {
      final short = requiredBytes - input.freeBytes;
      final missingMb = (short + _bytesPerMb - 1) ~/ _bytesPerMb;
      return PreflightOutcome._(
        block: PreflightBlock.noSpace,
        missingMb: missingMb,
      );
    }

    if (input.isPro) {
      return const PreflightOutcome.ok();
    }
    if (input.requestsProFeature) {
      return const PreflightOutcome._(block: PreflightBlock.proFeature);
    }
    final allowance = input.config.freeConversionsPerDay + input.rewardedToday;
    if (input.usedToday >= allowance) {
      return const PreflightOutcome._(block: PreflightBlock.freeLimit);
    }
    return const PreflightOutcome.ok();
  }
}
