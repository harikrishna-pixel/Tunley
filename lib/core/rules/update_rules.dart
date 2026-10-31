import 'dart:math' as math;

/// Update sheet (29, `05` §5): when config's `minRecommended` is newer than
/// the installed version. Once per `latest` version.
abstract final class UpdateRules {
  static bool shouldShow({
    required String current,
    required String latest,
    required String minRecommended,
    required String? shownForVersion,
  }) {
    if (compare(minRecommended, current) <= 0) return false;
    if (compare(latest, current) <= 0) return false;
    return shownForVersion != latest;
  }

  /// Compares dotted versions numerically ("1.10.0" > "1.9.2").
  static int compare(String a, String b) {
    List<int> parts(String v) => v
        .split(RegExp(r'[.+-]'))
        .take(3)
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final x = parts(a);
    final y = parts(b);
    for (var i = 0; i < math.max(x.length, y.length); i++) {
      final l = i < x.length ? x[i] : 0;
      final r = i < y.length ? y[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }
}
