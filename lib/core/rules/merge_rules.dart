import 'dart:math' as math;

/// Merge (41, `05` §11). Pro only, 2–10 inputs in list order.
abstract final class MergeRules {
  static const minFiles = 2;
  static const crossfadeOptions = [0, 1, 2, 3];
  static const defaultCrossfade = 1;

  static bool canMerge(int count, {required int maxFiles}) =>
      count >= minFiles && count <= maxFiles;

  /// How many more files the picker may add.
  static int room(int count, {required int maxFiles}) =>
      math.max(0, maxFiles - count);

  /// Sum − crossfades. Each crossfade is capped by the shorter neighbour.
  static double totalSeconds(List<double> durations, int crossfadeSec) {
    if (durations.isEmpty) return 0;
    var total = durations.first;
    for (var i = 1; i < durations.length; i++) {
      final overlap = math.min(
        crossfadeSec.toDouble(),
        math.min(durations[i - 1], durations[i]) / 2,
      );
      total += durations[i] - overlap;
    }
    return math.max(0, total);
  }
}
