import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/rules/paywall_triggers.dart';
import '../../core/rules/personalization.dart';
import '../../core/rules/pricing.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import 'paywall_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import 'checkout.dart';
import 'exit_offer_dialog.dart';

/// Opens P1. Requested sources (Pro chip, Settings, Go unlimited) never count
/// toward the unrequested cap.
Future<void> openPaywall(BuildContext context, PaywallSource source) async {
  await context.push('/paywall', extra: source);
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.source});

  final PaywallSource source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanKind _selected = PlanKind.yearly;
  bool _busy = false;
  PaywallView? _view;

  String get _trigger => paywallTrigger(widget.source);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _view = await PaywallView.open(context, trigger: _trigger);
    });
    if (widget.source == PaywallSource.onboarding) {
      Future.microtask(
        () => ref.read(paywallProvider.notifier).markShown(PaywallTrigger.p1),
      );
    }
  }

  Future<void> _close() async {
    final paywall = ref.read(paywallProvider.notifier);
    if (paywall.canShow(PaywallTrigger.p6, closingP1: true)) {
      final exit = await ref.read(plansProvider(OfferingId.exit).future);
      final plan = exit.where((p) => p.introEligible && p.introPrice != null);
      if (plan.isNotEmpty && mounted) {
        await paywall.markShown(PaywallTrigger.p6);
        if (!mounted) return;
        _view?.closed();
        final bought = await showExitOffer(context, ref, plan.first);
        if (!mounted) return;
        if (bought) return _done();
      }
    }
    _view?.closed();
    _done();
  }

  void _done() {
    ref.read(paywallProvider.notifier).noteClosed();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _buy(StorePlan plan) async {
    setState(() => _busy = true);
    final ok = await checkout(context, ref, plan, trigger: _trigger);
    if (ok) _view?.purchased();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _done();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final personal = ref.watch(personalizationProvider);
    final plansAsync = ref.watch(plansProvider(OfferingId.main));
    final plans = plansAsync.value ?? const <StorePlan>[];
    StorePlan? plan(PlanKind kind) =>
        plans.where((p) => p.kind == kind).firstOrNull;
    final yearly = plan(PlanKind.yearly);
    final weekly = plan(PlanKind.weekly);
    final selected = plan(_selected) ?? yearly;

    final header = switch (personal.goal) {
      UserGoal.ringtones => l10n.pwHeaderRingtones,
      UserGoal.mp3FromVideos => l10n.pwHeaderMp3,
      UserGoal.convertFiles => l10n.pwHeaderConvert,
    };
    final benefits = [
      personal.goal == UserGoal.ringtones
          ? l10n.pwBenefitRingtones
          : l10n.pwBenefitConversions,
      l10n.pwBenefitFormats,
      l10n.pwBenefitBatch,
      l10n.pwBenefitNoAds,
    ];

    final order = personal.lifetimeListedSecond
        ? [PlanKind.yearly, PlanKind.lifetime, PlanKind.weekly]
        : [PlanKind.yearly, PlanKind.weekly, PlanKind.lifetime];

    String terms() {
      final p = selected;
      if (p == null) return '';
      return switch (p.kind) {
        PlanKind.yearly =>
          p.showsTrial
              ? l10n.pwTermsTrial(p.trialDays!, p.priceString)
              : l10n.pwTermsYearly(p.priceString),
        PlanKind.weekly => l10n.pwTermsWeekly(p.priceString),
        _ => l10n.pwTermsLifetime(p.priceString),
      };
    }

    final cta = switch (selected?.kind) {
      PlanKind.yearly when selected!.showsTrial => l10n.pwCtaTrial,
      PlanKind.lifetime => l10n.pwCtaLifetime,
      _ => l10n.pwCtaContinue,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: Column(
          children: [
            // The header scrolls with the plans so 200% text never clips.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpace.s16),
                children: [
                  _Header(title: header, benefits: benefits, onClose: _close),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s20,
                      AppSpace.screen,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (plansAsync.isLoading)
                          Padding(
                            padding: const EdgeInsets.all(AppSpace.s24),
                            child: Text(
                              l10n.pwLoading,
                              textAlign: TextAlign.center,
                              style: text.caption.copyWith(color: colors.text2),
                            ),
                          )
                        else if (yearly == null)
                          StatusBox(
                            message: l10n.pwUnavailable,
                            tone: StatusTone.warn,
                          )
                        else ...[
                          if (yearly.showsTrial) ...[
                            _Timeline(yearly: yearly),
                            const SizedBox(height: AppSpace.s16),
                          ],
                          for (final kind in order)
                            if (plan(kind) case final p?) ...[
                              _PlanCard(
                                plan: p,
                                weekly: weekly,
                                selected: _selected == kind,
                                onTap: () {
                                  setState(() => _selected = kind);
                                  ref
                                      .read(analyticsProvider)
                                      .planSelected(
                                        plan: AnalyticsValues.planKind(kind),
                                        trigger: _trigger,
                                      );
                                },
                              ),
                              const SizedBox(height: AppSpace.s12),
                            ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      terms(),
                      textAlign: TextAlign.center,
                      style: text.caption.copyWith(color: colors.text2),
                    ),
                    const SizedBox(height: AppSpace.s10),
                    PrimaryButton(
                      label: cta,
                      onPressed: selected == null || _busy
                          ? null
                          : () => _buy(selected),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextLinkButton(
                          label: l10n.pwRestore,
                          muted: true,
                          onPressed: () => restorePurchases(context, ref),
                        ),
                        TextLinkButton(
                          label: l10n.settingsTerms,
                          muted: true,
                          onPressed: () =>
                              ref.read(audioEngineProvider).openUrl(termsUrl),
                        ),
                        TextLinkButton(
                          label: l10n.settingsPrivacy,
                          muted: true,
                          onPressed: () =>
                              ref.read(audioEngineProvider).openUrl(privacyUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.benefits,
    required this.onClose,
  });

  final String title;
  final List<String> benefits;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    Widget benefit(String label) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.check(PhosphorIconsStyle.bold),
              size: 12,
              color: colors.heroText,
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(
              label,
              style: text.subhead.copyWith(color: colors.heroText),
            ),
          ),
        ],
      ),
    );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.sheet),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.heroGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s16,
              AppSpace.s12,
              AppSpace.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s12,
                          vertical: AppSpace.s6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x29FFFFFF),
                          borderRadius: BorderRadius.circular(
                            AppRadius.proChip,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.crown(PhosphorIconsStyle.fill),
                              size: 16,
                              color: colors.gold,
                            ),
                            const SizedBox(width: AppSpace.s6),
                            Flexible(
                              child: Text(
                                l10n.pwBadge,
                                style: text.caption.copyWith(
                                  color: colors.heroText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      container: true,
                      button: true,
                      label: l10n.close,
                      child: InkResponse(
                        onTap: onClose,
                        radius: 24,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: PhosphorIcon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            color: colors.heroText,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s12),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.s8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: text.largeTitle.copyWith(color: colors.heroText),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Row(children: [benefit(benefits[0]), benefit(benefits[1])]),
                const SizedBox(height: AppSpace.s12),
                Row(children: [benefit(benefits[2]), benefit(benefits[3])]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.yearly});

  final StorePlan yearly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final timeline = TrialSchedule(
      start: DateTime.now(),
      trialDays: yearly.trialDays!,
    );
    Widget step(IconData icon, String title, String detail) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.link),
              const SizedBox(width: AppSpace.s4),
              Text(
                title,
                style: text.subhead.copyWith(
                  color: colors.link,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(detail, style: text.footnote.copyWith(color: colors.text2)),
        ],
      ),
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s12,
      ),
      child: Row(
        children: [
          step(PhosphorIcons.lockOpen(), l10n.pwToday, l10n.pwTodayDetail),
          step(
            PhosphorIcons.bell(),
            l10n.pwDay(timeline.dayNumber(timeline.reminderAt) - 1),
            l10n.pwReminder,
          ),
          step(
            PhosphorIcons.crown(PhosphorIconsStyle.fill),
            l10n.pwDay(timeline.dayNumber(timeline.chargeAt) - 1),
            l10n.pwStarts(yearly.priceString),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.weekly,
    required this.selected,
    required this.onTap,
  });

  final StorePlan plan;
  final StorePlan? weekly;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final locale = l10n.localeName;
    final (title, detail, price) = switch (plan.kind) {
      PlanKind.yearly => (
        l10n.pwYearly,
        plan.showsTrial
            ? l10n.pwYearlyTrial(plan.trialDays!, plan.priceString)
            : l10n.pwYearlyNoTrial,
        l10n.pwPerWeek(formatPrice(plan, Pricing.perWeek(plan.price), locale)),
      ),
      PlanKind.weekly => (
        l10n.pwWeekly,
        l10n.pwWeeklyDetail,
        l10n.pwPerWeek(plan.priceString),
      ),
      _ => (l10n.pwLifetime, l10n.pwLifetimeDetail, plan.priceString),
    };
    final save = plan.kind == PlanKind.yearly && weekly != null
        ? Pricing.savePercent(weekly: weekly!.price, yearly: plan.price)
        : 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s16,
                  vertical: AppSpace.s14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: selected ? colors.accent : colors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    RadioMark(selected: selected),
                    const SizedBox(width: AppSpace.s14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.navTitle),
                          Text(
                            detail,
                            style: text.caption.copyWith(color: colors.text2),
                          ),
                        ],
                      ),
                    ),
                    Text(price, style: text.navTitle),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (save > 0)
          Positioned(
            right: 16,
            top: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.success,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                l10n.pwSave(save),
                style: text.micro.copyWith(color: colors.accentText),
              ),
            ),
          ),
      ],
    );
  }
}
