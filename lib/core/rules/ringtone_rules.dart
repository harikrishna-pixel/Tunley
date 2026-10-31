import '../../app/config.dart';

enum ToneType { ringtone, alarm, textTone }

class ToneSelection {
  const ToneSelection({required this.start, required this.end});

  final Duration start;
  final Duration end;

  Duration get duration => end - start;
}

abstract final class RingtoneRules {
  static bool isPro(ToneType type) => type != ToneType.ringtone;

  static double snapFade(double seconds, {required int maxSeconds}) {
    final clamped = seconds.clamp(0, maxSeconds.toDouble()).toDouble();
    return (clamped * 2).round() / 2;
  }

  static String fileName(String source) {
    final trimmed = source.trim();
    final dot = trimmed.lastIndexOf('.');
    final base = dot > 0 ? trimmed.substring(0, dot) : trimmed;
    final name = base.trim().isEmpty ? 'tone' : base.trim();
    return '${name}_tone.m4r';
  }

  static ToneSelection defaultSelection({
    required Duration duration,
    required List<double> peaks,
    required ToneType type,
    required AppConfig config,
  }) {
    final windowSeconds = type == ToneType.textTone
        ? config.textToneDefaultSeconds
        : config.ringtoneMaxSeconds;
    final window = Duration(seconds: windowSeconds);
    if (duration <= window || peaks.isEmpty) {
      final end = duration.isNegative ? Duration.zero : duration;
      return ToneSelection(start: Duration.zero, end: end);
    }

    final samples = (windowSeconds / duration.inSeconds * peaks.length)
        .round()
        .clamp(1, peaks.length);
    var bestStart = 0;
    var running = 0.0;
    for (var i = 0; i < samples; i++) {
      running += peaks[i];
    }
    var bestSum = running;
    for (var start = 1; start + samples <= peaks.length; start++) {
      running += peaks[start + samples - 1] - peaks[start - 1];
      if (running > bestSum) {
        bestSum = running;
        bestStart = start;
      }
    }

    final startUs = (bestStart / peaks.length * duration.inMicroseconds)
        .round();
    final endUs =
        ((bestStart + samples) / peaks.length * duration.inMicroseconds)
            .round();
    return ToneSelection(
      start: Duration(microseconds: startUs),
      end: Duration(microseconds: endUs),
    );
  }
}
