import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/ads.dart';
import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/ads/ads_service.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../paywall/paywall_screen.dart';

enum AdBreakTrigger { save, ringtone, done }

/// Ad break (42 → 43) after Save to Files / Set as ringtone / Done on a fresh
/// Result. Our notice first; the network ad only after Continue; nothing of
/// ours over the ad. Skipped silently when not allowed or nothing is loaded.
Future<void> maybeAdBreak(
  BuildContext context,
  WidgetRef ref, {
  required AdBreakTrigger trigger,
  required String formatLabel,
  required bool ringtone,
  bool afterErrorInFlow = false,
  bool paywallInFlow = false,
  bool houseCardOnScreen = false,
}) async {
  final ads = ref.read(adsProvider.notifier);
  // Quiet-launch consent may have been skipped this session; start if we can.
  // Cap wait so offline / hung init never blocks Back / Done / ringtone.
  await ads.start();
  final lifetime = await ref.read(usageStoreProvider).lifetimeConversions();
  if (!context.mounted) return;
  final allowed = ads.canAdBreak(
    afterErrorInFlow: afterErrorInFlow,
    paywallInFlow: paywallInFlow,
    houseCardOnScreen: houseCardOnScreen,
    lifetimeConversions: lifetime,
  );
  if (!allowed) {
    if (kDebugMode && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ads skipped (policy / not started / Pro)')),
      );
    }
    return;
  }
  // Wait briefly if preload is in flight; skip if no fill (don't block nav).
  if (!ads.isReady(AdFormat.interstitial)) {
    await ads.preload(AdFormat.interstitial).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  }
  if (!context.mounted) return;
  if (!ads.isReady(AdFormat.interstitial)) {
    if (kDebugMode) {
      debugPrint(
        '[TunelyAds] skip notice 42: interstitial not ready (no fill / load fail)',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ad load failed — LevelPlay no fill. Check dashboard / Test Suite.',
          ),
        ),
      );
    }
    return;
  }

  final analytics = ref.read(analyticsProvider);
  analytics.adBreakShown(
    trigger: trigger.name,
    conversionsToday: ref.read(freeLimitProvider).usedToday,
  );
  final choice = await AppDialog.show<_AdChoice>(
    context: context,
    isDismissible: false,
    builder: (_) => AdBreakDialog(
      title: ringtone
          ? AppLocalizations.of(context).adBreakSavedRingtone
          : AppLocalizations.of(context).adBreakSavedAudio(formatLabel),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case _AdChoice.proceed:
      analytics.adBreakContinue();
      await ads.showAdBreak();
    case _AdChoice.removeAds:
      analytics.removeAdsTapped(screen: 'ad_break');
      await openPaywall(context, PaywallSource.removeAds);
    case null:
      break;
  }
}

enum _AdChoice { proceed, removeAds }

class AdBreakDialog extends StatelessWidget {
  const AdBreakDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.successSoft,
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: colors.success,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: text.dialogTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          l10n.adBreakBody,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(
          label: l10n.continueAction,
          onPressed: () => Navigator.of(context).pop(_AdChoice.proceed),
        ),
        const SizedBox(height: AppSpace.s8),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_AdChoice.removeAds),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            icon: PhosphorIcon(
              PhosphorIcons.crown(PhosphorIconsStyle.fill),
              color: colors.gold,
              size: 18,
            ),
            label: Text(
              l10n.adBreakRemoveAds,
              style: text.subhead.copyWith(
                color: colors.link,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
