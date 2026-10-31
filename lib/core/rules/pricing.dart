/// Display math on real store prices (`07`). Never a hard-coded price.
abstract final class Pricing {
  /// Yearly price per week, e.g. 29.99 → 0.58.
  static double perWeek(double yearly) => _cents(yearly / 52);

  /// Yearly price per month, e.g. 29.99 → 2.50.
  static double perMonth(double yearly) => _cents(yearly / 12);

  /// Yearly vs weekly saving, e.g. 4.99 / 29.99 → 88.
  static int savePercent({required double weekly, required double yearly}) {
    if (weekly <= 0 || yearly <= 0) return 0;
    final ratio = (yearly / 52) / weekly;
    return ((1 - ratio) * 100).floor().clamp(0, 99);
  }

  /// Discount of an offer vs the regular price, e.g. 14.99 / 29.99 → 50.
  static int discountPercent({required double regular, required double offer}) {
    if (regular <= 0 || offer <= 0 || offer >= regular) return 0;
    return ((1 - offer / regular) * 100).round().clamp(0, 99);
  }

  static double _cents(double value) => (value * 100).round() / 100;
}

/// P1 / P7 timeline for a free trial of [trialDays] starting [start].
class TrialSchedule {
  TrialSchedule({required DateTime start, required int trialDays})
    : started = start,
      chargeAt = start.add(Duration(days: trialDays)),
      reminderAt = start
          .add(Duration(days: trialDays))
          .subtract(const Duration(hours: 24));

  final DateTime started;

  /// When the first payment happens.
  final DateTime chargeAt;

  /// 24 h before the trial ends (O4 promise).
  final DateTime reminderAt;

  /// "Day 2" etc. counted from the start day.
  int dayNumber(DateTime moment) {
    final a = DateTime(started.year, started.month, started.day);
    final b = DateTime(moment.year, moment.month, moment.day);
    return b.difference(a).inDays + 1;
  }
}
