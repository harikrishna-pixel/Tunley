import 'free_limit.dart';

/// Persisted counters behind the ad caps (`05` §12).
class AdMemory {
  const AdMemory({
    this.lastAdAt,
    this.dayKey,
    this.adsToday = 0,
    this.conversionsSinceAd = 0,
    this.rewardedDayKey,
    this.rewardedToday = 0,
  });

  final DateTime? lastAdAt;
  final String? dayKey;
  final int adsToday;

  /// Successful conversions since the last ad break (or ever, before one).
  final int conversionsSinceAd;
  final String? rewardedDayKey;
  final int rewardedToday;

  int adsOn(String day) => dayKey == day ? adsToday : 0;
  int rewardedOn(String day) => rewardedDayKey == day ? rewardedToday : 0;

  AdMemory copyWith({
    DateTime? lastAdAt,
    String? dayKey,
    int? adsToday,
    int? conversionsSinceAd,
    String? rewardedDayKey,
    int? rewardedToday,
  }) {
    return AdMemory(
      lastAdAt: lastAdAt ?? this.lastAdAt,
      dayKey: dayKey ?? this.dayKey,
      adsToday: adsToday ?? this.adsToday,
      conversionsSinceAd: conversionsSinceAd ?? this.conversionsSinceAd,
      rewardedDayKey: rewardedDayKey ?? this.rewardedDayKey,
      rewardedToday: rewardedToday ?? this.rewardedToday,
    );
  }
}

class AdBreakRequest {
  const AdBreakRequest({
    required this.memory,
    required this.now,
    required this.isPro,
    required this.adsEnabled,
    required this.firstSession,
    required this.lifetimeConversions,
    required this.afterErrorInFlow,
    required this.paywallInFlow,
    required this.houseCardOnScreen,
    required this.firstSessionAds,
    required this.minConversionsBeforeFirstAd,
    required this.everyNthConversion,
    required this.minSecondsBetween,
    required this.maxPerDay,
  });

  final AdMemory memory;
  final DateTime now;
  final bool isPro;
  final bool adsEnabled;
  final bool firstSession;
  final int lifetimeConversions;
  final bool afterErrorInFlow;

  /// P4, P5 or P6 showed in this Result flow.
  final bool paywallInFlow;
  final bool houseCardOnScreen;
  final bool firstSessionAds;
  final int minConversionsBeforeFirstAd;
  final int everyNthConversion;
  final int minSecondsBetween;
  final int maxPerDay;
}

abstract final class AdPolicy {
  /// The ad break (42 → 43) after Save to Files / Set as ringtone / Done.
  static bool canShowAdBreak(AdBreakRequest r) {
    if (r.isPro || !r.adsEnabled) return false;
    if (r.firstSession && !r.firstSessionAds) return false;
    if (r.afterErrorInFlow || r.paywallInFlow || r.houseCardOnScreen) {
      return false;
    }
    if (r.lifetimeConversions < r.minConversionsBeforeFirstAd) return false;
    final first = r.memory.lastAdAt == null;
    if (!first && r.memory.conversionsSinceAd < r.everyNthConversion) {
      return false;
    }
    final last = r.memory.lastAdAt;
    if (last != null &&
        r.now.difference(last) < Duration(seconds: r.minSecondsBetween)) {
      return false;
    }
    return r.memory.adsOn(FreeLimit.dayKeyFor(r.now)) < r.maxPerDay;
  }

  /// "Watch a short ad for 1 more" on P3; also needs a loaded ad.
  static bool canOfferRewarded({
    required AdMemory memory,
    required DateTime now,
    required bool isPro,
    required bool adsEnabled,
    required int rewardedMaxPerDay,
  }) {
    if (isPro || !adsEnabled) return false;
    return memory.rewardedOn(FreeLimit.dayKeyFor(now)) < rewardedMaxPerDay;
  }

  static AdMemory afterConversion(AdMemory memory) =>
      memory.copyWith(conversionsSinceAd: memory.conversionsSinceAd + 1);

  static AdMemory afterAdBreak(AdMemory memory, DateTime now) {
    final day = FreeLimit.dayKeyFor(now);
    return memory.copyWith(
      lastAdAt: now,
      dayKey: day,
      adsToday: memory.adsOn(day) + 1,
      conversionsSinceAd: 0,
    );
  }

  static AdMemory afterReward(AdMemory memory, DateTime now) {
    final day = FreeLimit.dayKeyFor(now);
    return memory.copyWith(
      rewardedDayKey: day,
      rewardedToday: memory.rewardedOn(day) + 1,
    );
  }
}
