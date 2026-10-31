enum AudioPreset { standard, high, best, wav, flac, ogg, ringtone }

class SizeEstimate {
  const SizeEstimate({
    required this.bytes,
    required this.label,
    required this.approximate,
    this.sourceCaption,
  });

  final int bytes;
  final String label;
  final bool approximate;
  final String? sourceCaption;
}

abstract final class SizeEstimator {
  static const int _bytesPerMb = 1024 * 1024;

  static SizeEstimate estimate({
    required AudioPreset preset,
    required int seconds,
    int? sourceBitrateKbps,
  }) {
    final bytes = _bytes(preset, seconds);
    final target = _bitrateKbps(preset);
    final caption =
        target != null &&
            sourceBitrateKbps != null &&
            sourceBitrateKbps < target
        ? "Source is $sourceBitrateKbps kbps. Higher won't improve it."
        : null;
    return SizeEstimate(
      bytes: bytes,
      label: _label(bytes),
      approximate: preset == AudioPreset.flac,
      sourceCaption: caption,
    );
  }

  static int? _bitrateKbps(AudioPreset preset) {
    return switch (preset) {
      AudioPreset.standard => 128,
      AudioPreset.high => 256,
      AudioPreset.best => 320,
      AudioPreset.ogg => 256,
      AudioPreset.ringtone => 128,
      AudioPreset.wav || AudioPreset.flac => null,
    };
  }

  static int _bytes(AudioPreset preset, int seconds) {
    final kbps = _bitrateKbps(preset);
    if (kbps != null) {
      return (kbps * 1000 * seconds * 101) ~/ 800;
    }
    final wav = 44100 * 2 * 2 * seconds;
    if (preset == AudioPreset.flac) {
      return (wav * 0.55).round();
    }
    return wav;
  }

  static String _label(int bytes) {
    final mb = bytes / _bytesPerMb;
    if (mb >= 10) {
      return '~${mb.round()} MB';
    }
    return '~${mb.toStringAsFixed(1)} MB';
  }
}
