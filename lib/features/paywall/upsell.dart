import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/rules/pricing.dart';
import '../../l10n/app_localizations.dart';
import 'checkout.dart';
import 'paywall_analytics.dart';
import 'paywall_screen.dart';

/// P4 (09c): inline card on Result after the 3rd success of the day.
class UpsellCard extends ConsumerWidget {
  const UpsellCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final plans = ref.watch(plansProvider(OfferingId.main)).value;
    final yearly = plans?.where((p) => p.kind == PlanKind.yearly).firstOrNull;
    final trial = yearly?.showsTrial ?? false;
    return Material(
      color: colors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => openPaywall(context, PaywallSource.upsell),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.accent),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: colors.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: PhosphorIcon(
                  PhosphorIcons.crown(PhosphorIconsStyle.fill),
                  color: colors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpace.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.p4Title(count),
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      trial
                          ? l10n.p4TrialDetail(yearly!.trialDays!)
                          : l10n.p4NoTrialDetail,
                      style: text.caption.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.p4Cta,
                style: text.subhead.copyWith(
                  color: colors.link,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// P5 (13 / 13b): once, after the 10th file.
Future<void> showHeavyUser(BuildContext context, WidgetRef ref) async {
  final items = await ref.read(libraryRepositoryProvider).list();
  if (!context.mounted) return;
  final tones = items.where((i) => i.isTone).length;
  final mp3 = items.where((i) => !i.isTone && i.format == 'mp3').length;
  final other = items.length - tones - mp3;
  final view = await PaywallView.open(context, trigger: 'heavy_user');
  if (!context.mounted) return;
  await AppDialog.show<void>(
    context: context,
    builder: (_) =>
        _HeavyUser(total: items.length, mp3: mp3, tones: tones, other: other),
  );
  if (ref.read(entitlementProvider).isPro) {
    view.purchased();
  } else {
    view.closed();
  }
}

class _HeavyUser extends ConsumerStatefulWidget {
  const _HeavyUser({
    required this.total,
    required this.mp3,
    required this.tones,
    required this.other,
  });

  final int total;
  final int mp3;
  final int tones;
  final int other;

  @override
  ConsumerState<_HeavyUser> createState() => _HeavyUserState();
}

class _HeavyUserState extends ConsumerState<_HeavyUser> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final plans = ref.watch(plansProvider(OfferingId.main)).value;
    final yearly = plans?.where((p) => p.kind == PlanKind.yearly).firstOrNull;
    final trial = yearly?.showsTrial ?? false;

    Widget stat(int value, String label) => Expanded(
      child: Column(
        children: [
          Text('$value', style: text.navTitle),
          Text(label, style: text.footnote.copyWith(color: colors.text2)),
        ],
      ),
    );

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
              gradient: colors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.hero),
            ),
            child: PhosphorIcon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              color: colors.gold,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(
          l10n.p5Title(widget.total),
          textAlign: TextAlign.center,
          style: text.dialogTitle,
        ),
        const SizedBox(height: AppSpace.s14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            children: [
              stat(widget.mp3, l10n.p5StatMp3),
              stat(widget.tones, l10n.p5StatTones),
              stat(widget.other, l10n.p5StatOther),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s14),
        Text(
          l10n.p5Body,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        if (yearly != null) ...[
          const SizedBox(height: AppSpace.s14),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.row),
              border: Border.all(color: colors.accent, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pwYearly, style: text.navTitle),
                      Text(
                        trial
                            ? l10n.p5PlanTrial(
                                yearly.priceString,
                                yearly.trialDays!,
                              )
                            : l10n.p5PlanNoTrial(yearly.priceString),
                        style: text.footnote.copyWith(color: colors.text2),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.p5PerMonth(
                    formatPrice(
                      yearly,
                      Pricing.perMonth(yearly.price),
                      l10n.localeName,
                    ),
                  ),
                  style: text.navTitle,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: trial ? l10n.p5CtaTrial : l10n.p5CtaNoTrial,
          onPressed: yearly == null || _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final ok = await checkout(
                    context,
                    ref,
                    yearly,
                    trigger: 'heavy_user',
                  );
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (ok) Navigator.of(context).pop();
                },
        ),
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.notNow,
            muted: true,
            onPressed: () {
              ref.read(paywallProvider.notifier).noteClosed();
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
