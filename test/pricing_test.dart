import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/rules/pricing.dart';

void main() {
  test('yearly per week and per month from the store price', () {
    expect(Pricing.perWeek(29.99), 0.58);
    expect(Pricing.perMonth(29.99), 2.50);
  });

  test('SAVE % compares yearly with 52 weeks of weekly', () {
    expect(Pricing.savePercent(weekly: 4.99, yearly: 29.99), 88);
    expect(Pricing.savePercent(weekly: 0, yearly: 29.99), 0);
  });

  test('offer discounts', () {
    expect(Pricing.discountPercent(regular: 29.99, offer: 14.99), 50);
    expect(Pricing.discountPercent(regular: 29.99, offer: 17.99), 40);
    expect(Pricing.discountPercent(regular: 29.99, offer: 30), 0);
  });

  test('trial timeline: reminder 24 h before the charge on day 3', () {
    final start = DateTime(2026, 10, 24, 9);
    final timeline = TrialSchedule(start: start, trialDays: 3);
    expect(timeline.chargeAt, DateTime(2026, 10, 27, 9));
    expect(timeline.reminderAt, DateTime(2026, 10, 26, 9));
    expect(timeline.dayNumber(timeline.reminderAt), 3);
    expect(timeline.dayNumber(start), 1);
  });
}
