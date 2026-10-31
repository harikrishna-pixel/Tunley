import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/rules/pricing.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../paywall/paywall_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../paywall/checkout.dart';
import '../settings/settings_screen.dart';

/// P7 (15): the reminder promised in O4, 24 h before the trial ends.
/// P7 (15). [entry]: push (the notification) or in_app.
class TrialReminderScreen extends ConsumerStatefulWidget {
  const TrialReminderScreen({super.key, this.entry = 'in_app'});

  final String entry;

  @override
  ConsumerState<TrialReminderScreen> createState() =>
      _TrialReminderScreenState();
}

class _TrialReminderScreenState extends ConsumerState<TrialReminderScreen> {
  PaywallView? _view;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).trialReminderOpened(entry: widget.entry);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _view = await PaywallView.open(context, trigger: 'trial_reminder');
    });
  }

  @override
  void dispose() {
    _view?.closed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const _TrialReminderBody();
}

class _TrialReminderBody extends ConsumerWidget {
  const _TrialReminderBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final entitlement = ref.watch(entitlementProvider);
    final started = entitlement.trialStartedAt;
    final ends = entitlement.expiresAt;
    final items = ref.watch(libraryItemsProvider).value ?? const [];
    final made = started == null
        ? 0
        : items.where((i) => !i.createdAt.isBefore(started)).length;
    final yearly = ref
        .watch(plansProvider(OfferingId.main))
        .value
        ?.where((p) => p.kind == PlanKind.yearly)
        .firstOrNull;
    final date = DateFormat.MMMd(l10n.localeName);

    Widget row(IconData icon, Color color, String title, String detail) =>
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpace.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      detail,
                      style: text.footnote.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NavHeader(title: '', leading: NavLeading.close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s16,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.bell(),
                        color: colors.accentOnSoft,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s20),
                  Text(l10n.p7Title, style: text.largeTitle),
                  const SizedBox(height: AppSpace.s8),
                  if (ends != null)
                    Text(
                      l10n.p7Body(date.format(ends)),
                      style: text.body.copyWith(color: colors.text2),
                    ),
                  const SizedBox(height: AppSpace.s20),
                  ListGroup(
                    children: [
                      if (started != null)
                        row(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          colors.success,
                          l10n.p7Started(date.format(started)),
                          l10n.p7StartedDetail(made),
                        ),
                      row(
                        PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                        colors.accent,
                        l10n.p7Today,
                        l10n.p7TodayDetail,
                      ),
                      if (ends != null && yearly != null)
                        row(
                          PhosphorIcons.crown(PhosphorIconsStyle.fill),
                          colors.gold,
                          l10n.p7Charge(date.format(ends), yearly.priceString),
                          l10n.p7ChargeDetail,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ActionFooter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: l10n.p7Keep,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Center(
                    child: TextLinkButton(
                      label: l10n.p7Manage,
                      onPressed: () {
                        ref
                            .read(analyticsProvider)
                            .manageSubscriptionTapped(screen: 'trial_reminder');
                        ref
                            .read(audioEngineProvider)
                            .openUrl(
                              entitlement.managementUrl ??
                                  manageSubscriptionsUrl,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// P8 (16): lapsed subscriber, 14+ days after it ended, once per 90 days.
class WinBackScreen extends ConsumerStatefulWidget {
  const WinBackScreen({super.key});

  @override
  ConsumerState<WinBackScreen> createState() => _WinBackScreenState();
}

class _WinBackScreenState extends ConsumerState<WinBackScreen> {
  bool _busy = false;
  PaywallView? _view;

  int? get _daysSinceLapse {
    final lapsed = ref.read(entitlementProvider).lapsedAt;
    return lapsed == null ? null : DateTime.now().difference(lapsed).inDays;
  }

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).winbackShown(daysSinceLapse: _daysSinceLapse);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _view = await PaywallView.open(
        context,
        trigger: 'winback',
        offering: OfferingId.winBack,
      );
    });
  }

  void _close() {
    _view?.closed();
    ref.read(paywallProvider.notifier).noteClosed();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final plan = ref
        .watch(plansProvider(OfferingId.winBack))
        .value
        ?.firstOrNull;
    final items = ref.watch(libraryItemsProvider).value ?? const [];
    final last = items.where((i) => i.isTone).firstOrNull ?? items.firstOrNull;
    final percent = plan == null
        ? 0
        : Pricing.discountPercent(
            regular: plan.price,
            offer: plan.introPrice ?? plan.price,
          );

    String ago(DateTime when) {
      final days = DateTime.now().difference(when).inDays;
      return days >= 7
          ? l10n.relativeWeeks(days ~/ 7)
          : l10n.relativeDays(days.clamp(1, 6));
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          // The header scrolls with the offer so 200% text never clips.
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ClipRRect(
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
                          AppSpace.s8,
                          AppSpace.s12,
                          AppSpace.s24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Semantics(
                                button: true,
                                label: l10n.close,
                                child: InkResponse(
                                  onTap: _close,
                                  radius: 24,
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: PhosphorIcon(
                                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                                      color: colors.heroText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              l10n.p8Eyebrow,
                              style: text.subhead.copyWith(
                                color: const Color(0xCCFFFFFF),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s6),
                            Text(
                              l10n.p8Title(percent),
                              style: text.largeTitle.copyWith(
                                color: colors.heroText,
                              ),
                            ),
                            const SizedBox(height: AppSpace.s8),
                            Text(
                              l10n.p8Sub,
                              style: text.body.copyWith(
                                color: const Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (last != null) ...[
                        AppCard(
                          padding: const EdgeInsets.all(AppSpace.s14),
                          child: Row(
                            children: [
                              MediaThumb(
                                size: 52,
                                path: ref
                                    .read(libraryRepositoryProvider)
                                    .thumbnailPath(last),
                                isVideo: last.sourceIsVideo,
                              ),
                              const SizedBox(width: AppSpace.s14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      last.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.subhead.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      last.isTone
                                          ? l10n.p8LastTone(ago(last.createdAt))
                                          : l10n.p8LastFile(
                                              ago(last.createdAt),
                                            ),
                                      style: text.caption.copyWith(
                                        color: colors.text2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.s14),
                      ],
                      if (plan != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpace.s18),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.accent, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.p8Plan, style: text.navTitle),
                                    Text(
                                      l10n.p8PlanDetail(plan.priceString),
                                      style: text.caption.copyWith(
                                        color: colors.text2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    plan.priceString,
                                    style: text.caption.copyWith(
                                      color: colors.text2,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    plan.introPriceString ?? plan.priceString,
                                    style: text.dialogTitle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // TODO(question #7): show "Offer valid until" once the offer end date is known from the store.
                    ],
                  ),
                ),
              ],
            ),
          ),
          ActionFooter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: l10n.p8Cta(percent),
                  onPressed: plan == null || _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          final ok = await checkout(
                            context,
                            ref,
                            plan,
                            trigger: 'winback',
                          );
                          if (ok) {
                            _view?.purchased();
                            ref
                                .read(analyticsProvider)
                                .winbackAccepted(
                                  daysSinceLapse: _daysSinceLapse,
                                );
                          }
                          if (!mounted) return;
                          setState(() => _busy = false);
                          if (ok) _close();
                        },
                ),
                const SizedBox(height: AppSpace.s4),
                Center(
                  child: TextLinkButton(
                    label: l10n.p8Continue,
                    muted: true,
                    onPressed: _close,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
