import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/rules/personalization.dart';
import 'checkout.dart';

/// `paywall_viewed.trigger` / `paywall_closed.trigger` values (`08`).
String paywallTrigger(PaywallSource source) => switch (source) {
  PaywallSource.onboarding => 'onboarding',
  PaywallSource.proChip => 'home_chip',
  PaywallSource.settings => 'settings',
  PaywallSource.result => 'result',
  PaywallSource.limit => 'daily_limit',
  PaywallSource.feature => 'pro_feature',
  PaywallSource.upsell => 'upsell_card',
  PaywallSource.removeAds => 'remove_ads',
};

/// Personalised paywall layout (`05` §3) for `paywall_viewed.variant`.
String paywallVariant(Personalization p) {
  if (p.emphasiseYearly) return 'yearly_first';
  if (p.lifetimeListedSecond) return 'lifetime_second';
  return 'default';
}

/// Tracks one paywall / sheet / card from visible to closed.
class PaywallView {
  PaywallView._(this._analytics, this.trigger) : _shownAt = DateTime.now();

  final Analytics _analytics;
  final String trigger;
  final DateTime _shownAt;
  bool _closed = false;

  /// `paywall_viewed` with trial eligibility from the store.
  static Future<PaywallView> open(
    BuildContext context, {
    required String trigger,
    String? feature,
    OfferingId offering = OfferingId.main,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final analytics = container.read(analyticsProvider);
    final view = PaywallView._(analytics, trigger);
    final p = container.read(personalizationProvider);
    var eligible = false;
    try {
      final plans = await container.read(plansProvider(offering).future);
      // Trial is Yearly only; Weekly must never count as trial-eligible.
      eligible = plans.any((plan) => plan.showsTrial);
    } on Object {
      eligible = false;
    }
    analytics.paywallViewed(
      trigger: trigger,
      variant: paywallVariant(p),
      goal: AnalyticsValues.goal(p.goal),
      trialEligible: eligible,
      feature: feature,
    );
    return view;
  }

  /// `paywall_closed` unless a purchase closed it.
  void closed() {
    if (_closed) return;
    _closed = true;
    _analytics.paywallClosed(
      trigger: trigger,
      secondsOnScreen:
          DateTime.now().difference(_shownAt).inMilliseconds / 1000,
    );
  }

  void purchased() => _closed = true;
}
