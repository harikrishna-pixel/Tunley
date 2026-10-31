/// Display formatting shared by screens. No business rules here.
abstract final class Fmt {
  /// `0:42`, `3:15`, `1:05:02`.
  static String duration(double seconds) {
    final total = seconds.isFinite ? seconds.round().clamp(0, 359999) : 0;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  /// `0:12.40` for the trim editor.
  static String timecode(double seconds) {
    final safe = seconds.isFinite && seconds > 0 ? seconds : 0.0;
    final whole = safe.floor();
    final hundredths = ((safe - whole) * 100).floor().toString().padLeft(
      2,
      '0',
    );
    return '${duration(whole.toDouble())}.$hundredths';
  }

  /// `1.3 MB` under 10 MB, `86 MB` above, `1.2 GB` from 1 GB.
  static String bytes(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= 1024 * mb) {
      return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
    }
    final value = bytes / mb;
    return value >= 10
        ? '${value.round()} MB'
        : '${value.toStringAsFixed(1)} MB';
  }

  /// `3 s` / `1 min 4 s` for "Took".
  static String took(int milliseconds) {
    final seconds = (milliseconds / 1000).ceil().clamp(1, 1 << 30);
    if (seconds < 60) return '$seconds s';
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }

  static String extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toUpperCase() : '';
  }

  static String baseName(String name) {
    final file = name.split('/').last;
    final dot = file.lastIndexOf('.');
    return dot > 0 ? file.substring(0, dot) : file;
  }
}
