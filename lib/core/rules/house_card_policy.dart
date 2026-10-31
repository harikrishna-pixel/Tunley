import 'free_limit.dart';

/// Persisted state of the Marberx card on Result (09d, `05` §13).
class HouseCardMemory {
  const HouseCardMemory({
    this.lastShownAt,
    this.hiddenUntil,
    this.hideCount = 0,
  });

  final DateTime? lastShownAt;
  final DateTime? hiddenUntil;
  final int hideCount;

  HouseCardMemory copyWith({
    DateTime? lastShownAt,
    DateTime? hiddenUntil,
    int? hideCount,
  }) {
    return HouseCardMemory(
      lastShownAt: lastShownAt ?? this.lastShownAt,
      hiddenUntil: hiddenUntil ?? this.hiddenUntil,
      hideCount: hideCount ?? this.hideCount,
    );
  }
}

class HouseCardRequest {
  const HouseCardRequest({
    required this.memory,
    required this.now,
    required this.installedAt,
    required this.isPro,
    required this.success,
    required this.lifetimeSuccesses,
    required this.adBreakThisSession,
    required this.upsellCardShowing,
    required this.everyNthSuccess,
    required this.minDaysSinceInstall,
  });

  final HouseCardMemory memory;
  final DateTime now;
  final DateTime installedAt;
  final bool isPro;
  final bool success;
  final int lifetimeSuccesses;
  final bool adBreakThisSession;
  final bool upsellCardShowing;
  final int everyNthSuccess;
  final int minDaysSinceInstall;
}

abstract final class HouseCardPolicy {
  static const maxHides = 3;

  static bool canShow(HouseCardRequest r) {
    if (!r.success || r.adBreakThisSession || r.upsellCardShowing) {
      return false;
    }
    if (r.memory.hideCount >= maxHides) return false;
    final hidden = r.memory.hiddenUntil;
    if (hidden != null && r.now.isBefore(hidden)) return false;
    if (r.now.isBefore(
      r.installedAt.add(Duration(days: r.minDaysSinceInstall)),
    )) {
      return false;
    }
    if (r.everyNthSuccess <= 0 ||
        r.lifetimeSuccesses % r.everyNthSuccess != 0) {
      return false;
    }
    final last = r.memory.lastShownAt;
    if (last == null) return true;
    if (r.isPro) return r.now.difference(last) >= const Duration(days: 7);
    return FreeLimit.dayKeyFor(last) != FreeLimit.dayKeyFor(r.now);
  }

  static HouseCardMemory shown(HouseCardMemory memory, DateTime now) =>
      memory.copyWith(lastShownAt: now);

  /// × hides it for [hideDays]; hidden [maxHides] times → never again.
  static HouseCardMemory hidden(
    HouseCardMemory memory,
    DateTime now, {
    required int hideDays,
  }) {
    return memory.copyWith(
      hiddenUntil: now.add(Duration(days: hideDays)),
      hideCount: memory.hideCount + 1,
    );
  }

  /// The Marberx app that fits what the user just did (`05` §13): a video →
  /// Shrink; otherwise the first other app. Ids from `app_config.json`.
  static String? pick(List<String> appIds, {required bool fromVideo}) {
    if (appIds.isEmpty) return null;
    if (fromVideo && appIds.contains('shrink')) return 'shrink';
    return appIds.firstWhere(
      (id) => id != 'shrink',
      orElse: () => appIds.first,
    );
  }
}
