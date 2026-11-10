import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../core/design_system/design_system.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import 'paywall_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../../core/engine/audio_engine.dart';
import 'checkout.dart'; // plansProvider
import 'paywall_screen.dart';

/// Sheet result: free alternative chosen, or open the main paywall.
enum _ProGateResult { freeAlternative, openPaywall }

/// P2 (11 / 11b): a gate on a Pro control. Never counts a conversion.
abstract final class ProGateSheet {
  /// Returns true when the user chose the free alternative.
  /// [analyticsFeature]: flac · aac · ogg · alarm · text_tone · boost ·
  /// merge · batch (`08`).
  static Future<bool> show(
    BuildContext context, {
    required String feature,
    required String analyticsFeature,
    String? detail,
    bool isFormat = false,
    String? freeAlternative,
  }) async {
    final analytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(analyticsProvider);
    analytics.proFeatureTapped(feature: analyticsFeature);
    final view = await PaywallView.open(
      context,
      trigger: 'pro_feature',
      feature: analyticsFeature,
    );
    if (!context.mounted) return false;
    final result = await AppBottomSheet.show<_ProGateResult>(
      context: context,
      builder: (_) => _FeatureSheet(
        feature: feature,
        detail: detail,
        isFormat: isFormat,
        freeAlternative: freeAlternative,
      ),
    );
    final container = context.mounted
        ? ProviderScope.containerOf(context, listen: false)
        : null;
    if (result == _ProGateResult.openPaywall && context.mounted) {
      view.closed();
      await openPaywall(context, PaywallSource.feature);
    } else if (container?.read(entitlementProvider).isPro ?? false) {
      view.purchased();
    } else {
      view.closed();
    }
    if (result == _ProGateResult.freeAlternative) {
      analytics.freeAlternativeUsed(feature: analyticsFeature);
      return true;
    }
    return false;
  }
}

class _FeatureSheet extends ConsumerWidget {
  const _FeatureSheet({
    required this.feature,
    required this.detail,
    required this.isFormat,
    required this.freeAlternative,
  });

  final String feature;
  final String? detail;
  final bool isFormat;
  final String? freeAlternative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final plans = ref.watch(plansProvider(OfferingId.main)).value;
    final yearly = plans?.where((p) => p.kind == PlanKind.yearly).firstOrNull;
    final trial = yearly?.showsTrial ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.row),
              ),
              child: PhosphorIcon(
                isFormat
                    ? PhosphorIcons.fileAudio()
                    : PhosphorIcons.crown(PhosphorIconsStyle.fill),
                color: isFormat ? colors.heroText : colors.gold,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpace.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFormat
                        ? l10n.p2FormatTitle(feature)
                        : l10n.p2FeatureTitle(feature),
                    style: text.dialogTitle,
                  ),
                  Text(
                    detail ?? l10n.p2DetailPro,
                    style: text.caption.copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        Container(
          padding: const EdgeInsets.all(AppSpace.s14),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.row),
          ),
          child: Column(
            children: [
              for (final benefit in [
                l10n.p2Benefit1,
                l10n.p2Benefit2,
                l10n.p2Benefit3,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        color: colors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpace.s10),
                      Expanded(child: Text(benefit, style: text.subhead)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: trial
              ? l10n.p2CtaTrial(yearly!.trialDays!)
              : l10n.p2CtaNoTrial,
          onPressed: () =>
              Navigator.of(context).pop(_ProGateResult.openPaywall),
        ),
        if (freeAlternative != null) ...[
          const SizedBox(height: AppSpace.s4),
          Center(
            child: TextLinkButton(
              label: freeAlternative!,
              onPressed: () =>
                  Navigator.of(context).pop(_ProGateResult.freeAlternative),
            ),
          ),
        ],
      ],
    );
  }
}

/// P2 subtitle for a Pro format.
String formatDetail(AppLocalizations l10n, OutFormat format) =>
    switch (format) {
      OutFormat.flac => l10n.p2DetailFlac,
      OutFormat.aac => l10n.p2DetailAac,
      OutFormat.ogg => l10n.p2DetailOgg,
      _ => l10n.p2DetailPro,
    };
