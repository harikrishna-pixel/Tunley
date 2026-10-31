import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/entitlements/purchases.dart';
import '../core/rules/paywall_triggers.dart';
import '../features/paywall/checkout.dart';
import '../features/paywall/exit_offer_dialog.dart';
import '../features/prompts/update_dialog.dart';
import '../core/library/usage_store.dart';
import '../features/ads/ads_consent_screen.dart';
import 'ads.dart';
import 'monetization.dart';
import 'state.dart';

/// Offers that can open at launch, at most one: the reminder the user tapped,
/// an exit offer whose real timer is still running, the in-app trial reminder
/// when notifications are off (P7), or win-back (P8). Otherwise the update
/// sheet (29) when config recommends a newer version. On a launch with none
/// of these: ads consent (UMP → 44 → ATT), once.
Future<void> runLaunchOffers(BuildContext context, WidgetRef ref) async {
  final shown = await _offers(context, ref);
  if (!context.mounted) return;
  if (shown) {
    // Consent waits for a quiet launch; ads start only once it is resolved.
    if (await ref.read(usageStoreProvider).trackingPromptShown()) {
      await ref.read(adsProvider.notifier).start();
    }
    return;
  }
  await runAdsConsent(context, ref);
}

/// At most one; returns whether something was shown.
Future<bool> _offers(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final paywall = ref.read(paywallProvider.notifier);
  final reminder = ref.read(trialReminderProvider);

  if (await reminder.openedFromReminder) {
    await paywall.markShown(PaywallTrigger.p7);
    router.push('/trial-reminder', extra: 'push');
    return true;
  }

  if (paywall.exitOfferResumable) {
    final plans = await ref.read(plansProvider(OfferingId.exit).future);
    final plan = plans.where((p) => p.introEligible && p.introPrice != null);
    if (plan.isNotEmpty && context.mounted) {
      await showExitOffer(context, ref, plan.first);
      return true;
    }
  }

  if (paywall.canShow(PaywallTrigger.p7) &&
      !await reminder.notificationsAllowed()) {
    await paywall.markShown(PaywallTrigger.p7);
    router.push('/trial-reminder');
    return true;
  }

  if (paywall.canShow(PaywallTrigger.p8)) {
    final plans = await ref.read(plansProvider(OfferingId.winBack).future);
    if (plans.isNotEmpty) {
      await paywall.markShown(PaywallTrigger.p8);
      router.push('/winback');
      return true;
    }
  }

  return context.mounted && await maybeShowUpdate(context, ref);
}
