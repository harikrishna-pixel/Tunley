class FreeLimitSnapshot {
  const FreeLimitSnapshot({
    required this.usedToday,
    required this.rewardedToday,
    required this.dayKey,
    required this.maxDayKey,
  });

  final int usedToday;
  final int rewardedToday;

  /// Local calendar day, `yyyy-MM-dd`.
  final String dayKey;

  /// Latest day key ever observed. A clock set backwards cannot pass it.
  final String maxDayKey;

  FreeLimitSnapshot copyWith({
    int? usedToday,
    int? rewardedToday,
    String? dayKey,
    String? maxDayKey,
  }) {
    return FreeLimitSnapshot(
      usedToday: usedToday ?? this.usedToday,
      rewardedToday: rewardedToday ?? this.rewardedToday,
      dayKey: dayKey ?? this.dayKey,
      maxDayKey: maxDayKey ?? this.maxDayKey,
    );
  }
}

abstract final class FreeLimit {
  static String dayKeyFor(DateTime instant) {
    final local = instant.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static FreeLimitSnapshot reconcile(FreeLimitSnapshot state, DateTime now) {
    final today = dayKeyFor(now);
    if (today.compareTo(state.maxDayKey) < 0) {
      return state;
    }
    if (today == state.dayKey) {
      return state.maxDayKey == today
          ? state
          : state.copyWith(maxDayKey: today);
    }
    return FreeLimitSnapshot(
      usedToday: 0,
      rewardedToday: 0,
      dayKey: today,
      maxDayKey: today,
    );
  }

  static bool isAtLimit(
    FreeLimitSnapshot state, {
    required int freePerDay,
    bool isPro = false,
  }) {
    if (isPro) {
      return false;
    }
    return state.usedToday >= freePerDay + state.rewardedToday;
  }

  /// +1 free conversion today, only from the rewarded ad's reward callback.
  static FreeLimitSnapshot recordRewarded(FreeLimitSnapshot state) =>
      state.copyWith(rewardedToday: state.rewardedToday + 1);

  /// Counts a conversion only when a new job finishes and the file exists.
  static FreeLimitSnapshot recordFinished(
    FreeLimitSnapshot state, {
    required bool success,
    required bool outputExists,
    required bool isNewConversion,
  }) {
    if (!success || !outputExists || !isNewConversion) {
      return state;
    }
    return state.copyWith(usedToday: state.usedToday + 1);
  }
}
