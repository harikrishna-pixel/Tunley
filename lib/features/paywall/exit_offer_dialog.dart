import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/monetization.dart';
import '../../core/design_system/design_system.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/rules/pricing.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import 'paywall_analytics.dart';
import '../../l10n/app_localizations.dart';
import 'checkout.dart';

/// P6: once ever, real persisted 10-minute timer. Returns true when bought.
Future<bool> showExitOffer(
  BuildContext context,
  WidgetRef ref,
  StorePlan plan,
) async {
  final result = await AppDialog.show<bool>(
    context: context,
    isDismissible: false,
    padding: EdgeInsets.zero,
    builder: (_) => _ExitOffer(plan: plan),
  );
  if (result == true) {
    ref
        .read(analyticsProvider)
        .exitOfferAccepted(secondsLeft: _secondsLeft(ref));
  }
  await ref.read(paywallProvider.notifier).finishExitOffer();
  return result ?? false;
}

int _secondsLeft(WidgetRef ref) {
  final ends = ref.read(paywallProvider).memory.exitEndsAt;
  if (ends == null) return 0;
  return ends.difference(DateTime.now()).inSeconds.clamp(0, 1 << 30);
}

class _ExitOffer extends ConsumerStatefulWidget {
  const _ExitOffer({required this.plan});

  final StorePlan plan;

  @override
  ConsumerState<_ExitOffer> createState() => _ExitOfferState();
}

class _ExitOfferState extends ConsumerState<_ExitOffer> {
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _busy = false;
  PaywallView? _view;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).exitOfferShown(secondsLeft: _secondsLeft(ref));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _view = await PaywallView.open(
        context,
        trigger: 'exit_offer',
        offering: OfferingId.exit,
      );
    });
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final memory = ref.read(paywallProvider).memory;
    final minutes = ref.read(appConfigProvider).exitOfferMinutes;
    final ends =
        memory.exitEndsAt ?? DateTime.now().add(Duration(minutes: minutes));
    final left = ends.difference(DateTime.now());
    if (left <= Duration.zero) {
      _timer?.cancel();
      ref.read(analyticsProvider).exitOfferExpired();
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _view?.closed();
    super.dispose();
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final ok = await checkout(context, ref, widget.plan, trigger: 'exit_offer');
    if (ok) _view?.purchased();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final plan = widget.plan;
    final percent = Pricing.discountPercent(
      regular: plan.price,
      offer: plan.introPrice ?? plan.price,
    );
    final minutes = _left.inMinutes.toString().padLeft(2, '0');
    final seconds = (_left.inSeconds % 60).toString().padLeft(2, '0');
    Widget digit(String value) => Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(value, style: text.timecode),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: colors.heroGradient),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s24,
                  AppSpace.s24,
                  AppSpace.s24,
                  AppSpace.s24,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(AppRadius.row),
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.gift(),
                        color: colors.heroText,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s12),
                    Text(
                      l10n.p6Eyebrow,
                      style: text.subhead.copyWith(color: colors.heroText),
                    ),
                    SizedBox(
                      height: 64,
                      child: FittedBox(
                        child: Text(
                          l10n.p6Off(percent),
                          style: text.timecode.copyWith(color: colors.heroText),
                        ),
                      ),
                    ),
                    Text(
                      l10n.p6Sub,
                      style: text.body.copyWith(color: colors.heroText),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Semantics(
                  button: true,
                  label: l10n.close,
                  child: InkResponse(
                    onTap: () => Navigator.of(context).pop(false),
                    radius: 24,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: PhosphorIcon(
                        PhosphorIcons.x(PhosphorIconsStyle.bold),
                        color: colors.heroText,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.priceString,
                    style: text.body.copyWith(
                      color: colors.text2,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s10),
                  Text(
                    l10n.p6Price(plan.introPriceString ?? plan.priceString),
                    style: text.dialogTitle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s14),
              Text(
                l10n.p6EndsIn,
                textAlign: TextAlign.center,
                style: text.caption.copyWith(color: colors.text2),
              ),
              const SizedBox(height: AppSpace.s8),
              Semantics(
                liveRegion: true,
                label: '$minutes:$seconds',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      digit(minutes),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s10,
                        ),
                        child: Text(':', style: text.timecode),
                      ),
                      digit(seconds),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s20),
              PrimaryButton(
                label: l10n.p6Cta(percent),
                onPressed: _busy ? null : _claim,
              ),
              const SizedBox(height: AppSpace.s10),
              Text(
                l10n.p6Terms(
                  plan.introPriceString ?? plan.priceString,
                  plan.priceString,
                ),
                textAlign: TextAlign.center,
                style: text.footnote.copyWith(color: colors.text2),
              ),
              const SizedBox(height: AppSpace.s4),
              Center(
                child: TextLinkButton(
                  label: l10n.p6NoThanks,
                  muted: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
