import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/ads.dart';
import '../../app/config.dart';
import '../../core/ads/ads_service.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import 'paywall_analytics.dart';
import 'paywall_screen.dart';

/// P3 (12): real countdown to local midnight. A user-initiated gate, so it
/// doesn't count toward the unrequested cap.
Future<void> showDailyLimit(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final ads = container.read(adsProvider.notifier);
  unawaited(ads.preload(AdFormat.rewarded));
  container
      .read(analyticsProvider)
      .limitReached(usedToday: container.read(freeLimitProvider).usedToday);
  final view = await PaywallView.open(context, trigger: 'daily_limit');
  if (!context.mounted) return;
  final choice = await AppDialog.show<_LimitChoice>(
    context: context,
    builder: (_) => const _DailyLimit(),
  );
  view.closed();
  if (!context.mounted) return;
  switch (choice) {
    case _LimitChoice.pro:
      await openPaywall(context, PaywallSource.limit);
    case _LimitChoice.rewarded:
      final earned = await ads.watchRewarded();
      if (!earned || !context.mounted) return;
      container
          .read(analyticsProvider)
          .rewardedEarned(rewardedToday: ads.rewardedToday() + 1);
      TunelyToast.show(
        context,
        message: AppLocalizations.of(context).rewardedEarned,
      );
    case null:
      break;
  }
}

enum _LimitChoice { pro, rewarded }

class _DailyLimit extends ConsumerStatefulWidget {
  const _DailyLimit();

  @override
  ConsumerState<_DailyLimit> createState() => _DailyLimitState();
}

class _DailyLimitState extends ConsumerState<_DailyLimit> {
  Timer? _timer;
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final total = ref.watch(appConfigProvider).freeConversionsPerDay;
    final used = ref.watch(freeLimitProvider).usedToday;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final left = midnight.difference(now);
    String two(int v) => v.toString().padLeft(2, '0');
    final countdown =
        '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
    // Re-checked every tick: the button appears once an ad has loaded.
    final ads = ref.read(adsProvider.notifier);
    final rewarded = ads.canOfferRewarded();
    if (rewarded && !_offered) {
      _offered = true;
      ref
          .read(analyticsProvider)
          .rewardedOffered(rewardedToday: ads.rewardedToday());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.s6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < used ? colors.accent : colors.surface2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.s14),
        Text(
          l10n.p3Used(used.clamp(0, total), total),
          style: text.caption.copyWith(
            color: colors.text2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s6),
        Text(l10n.p3Title, style: text.dialogTitle),
        const SizedBox(height: AppSpace.s8),
        Text(l10n.p3Body, style: text.body.copyWith(color: colors.text2)),
        const SizedBox(height: AppSpace.s16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s14,
          ),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.p3ResetsIn,
                  style: text.caption.copyWith(
                    color: colors.text2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Semantics(
                label: countdown,
                child: ExcludeSemantics(
                  child: Text(
                    countdown,
                    style: text.navTitle.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: l10n.p3Cta,
          onPressed: () => Navigator.of(context).pop(_LimitChoice.pro),
        ),
        if (rewarded) ...[
          const SizedBox(height: AppSpace.s10),
          SecondaryButton(
            label: l10n.rewardedWatch,
            icon: PhosphorIcons.play(PhosphorIconsStyle.fill),
            onPressed: () => Navigator.of(context).pop(_LimitChoice.rewarded),
          ),
        ],
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.p3Tomorrow,
            muted: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
