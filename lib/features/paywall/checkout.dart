import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../core/design_system/design_system.dart';
import '../../core/entitlements/purchases.dart';
import '../../core/notifications/trial_reminder.dart';
import '../../core/rules/pricing.dart';
import '../../app/analytics_sync.dart';
import '../../app/state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../core/library/usage_store.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_screen.dart';
import '../prompts/notification_prompt.dart';

final trialReminderProvider = Provider<TrialReminder>(
  (_) => throw StateError('trialReminder must be overridden at startup.'),
);

/// Fresh plans (and trial eligibility) every time a paywall opens.
final plansProvider = FutureProvider.autoDispose
    .family<List<StorePlan>, OfferingId>(
      (ref, offering) => ref.watch(purchasesServiceProvider).plans(offering),
    );

/// Buys [plan] and handles every outcome (`07` P9). Returns true on success.
/// [trigger] is the `paywall_viewed.trigger` of the surface that sold it.
Future<bool> checkout(
  BuildContext context,
  WidgetRef ref,
  StorePlan plan, {
  required String trigger,
}) async {
  final l10n = AppLocalizations.of(context);
  final service = ref.read(purchasesServiceProvider);
  final analytics = ref.read(analyticsProvider);
  final planName = AnalyticsValues.planKind(plan.kind);
  final price = plan.introEligible && plan.introPrice != null
      ? plan.introPrice!
      : plan.price;
  while (true) {
    analytics.purchaseStarted(
      plan: planName,
      trigger: trigger,
      price: price,
      currency: plan.currencyCode,
    );
    final outcome = await service.purchase(plan);
    switch (outcome) {
      case PurchaseOutcome.success:
        if (plan.showsTrial) {
          analytics.trialStarted(plan: planName, trigger: trigger);
        } else {
          analytics.purchaseSucceeded(
            plan: planName,
            trigger: trigger,
            price: price,
            currency: plan.currencyCode,
          );
        }
        await ref.read(usageStoreProvider).setLastPlanKind(plan.kind);
        await ref.read(analyticsSyncProvider).refreshEntitlement();
      case PurchaseOutcome.cancelled:
        analytics.purchaseCancelled(plan: planName, trigger: trigger);
      case PurchaseOutcome.pending:
        analytics.purchasePending(plan: planName);
      case PurchaseOutcome.offline:
      case PurchaseOutcome.unavailable:
        analytics.purchaseOffline(action: 'buy');
      case PurchaseOutcome.failed:
        analytics.purchaseFailed(
          plan: planName,
          trigger: trigger,
          errorCode: outcome.name,
        );
    }
    if (!context.mounted) return outcome == PurchaseOutcome.success;
    switch (outcome) {
      case PurchaseOutcome.success:
        await _afterPurchase(context, ref, plan, l10n);
        if (context.mounted) {
          TunelyToast.show(
            context,
            message: l10n.welcomePro,
            tone: ToastTone.info,
            icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
          );
        }
        return true;
      case PurchaseOutcome.cancelled:
        return false;
      case PurchaseOutcome.pending:
        await showPurchaseResult(context, ref, PurchaseResultKind.pending);
        return false;
      case PurchaseOutcome.offline:
      case PurchaseOutcome.unavailable:
        await showPurchaseResult(context, ref, PurchaseResultKind.offline);
        return false;
      case PurchaseOutcome.failed:
        final retry = await showPurchaseResult(
          context,
          ref,
          PurchaseResultKind.failed,
        );
        if (retry != true || !context.mounted) return false;
    }
  }
}

/// Trial started: remind 24 h before it ends. Lifetime or paid: no reminder.
Future<void> _afterPurchase(
  BuildContext context,
  WidgetRef ref,
  StorePlan plan,
  AppLocalizations l10n,
) async {
  final reminder = ref.read(trialReminderProvider);
  if (!plan.showsTrial) {
    await reminder.cancel();
    return;
  }
  final allowed =
      context.mounted &&
      await askNotifications(context, ref, NotifyReason.trial);
  if (!allowed) return;
  final timeline = TrialSchedule(
    start: DateTime.now(),
    trialDays: plan.trialDays!,
  );
  await reminder.schedule(
    timeline.reminderAt,
    title: l10n.p7NotificationTitle,
    body: l10n.p7NotificationBody,
  );
  ref
      .read(analyticsProvider)
      .trialReminderScheduled(
        hoursBeforeEnd: timeline.chargeAt
            .difference(timeline.reminderAt)
            .inHours,
      );
}

Future<void> restorePurchases(BuildContext context, WidgetRef ref) async {
  final outcome = await ref.read(purchasesServiceProvider).restore();
  final analytics = ref.read(analyticsProvider);
  if (outcome == RestoreOutcome.offline) {
    analytics.purchaseOffline(action: 'restore');
  }
  await ref.read(analyticsSyncProvider).refreshEntitlement();
  final entitlement = ref.read(entitlementProvider);
  analytics.restoreResult(
    result: switch (outcome) {
      RestoreOutcome.restored => 'restored',
      RestoreOutcome.none => 'none',
      RestoreOutcome.offline => 'offline',
      RestoreOutcome.failed => 'error',
    },
    plan: entitlement.isPro
        ? AnalyticsValues.plan(
            entitlement,
            lastKind: await ref.read(usageStoreProvider).lastPlanKind(),
          )
        : null,
  );
  if (!context.mounted) return;
  await showPurchaseResult(context, ref, switch (outcome) {
    RestoreOutcome.restored => PurchaseResultKind.restored,
    RestoreOutcome.none => PurchaseResultKind.none,
    RestoreOutcome.offline => PurchaseResultKind.offline,
    RestoreOutcome.failed => PurchaseResultKind.failed,
  });
}

enum PurchaseResultKind { failed, restored, pending, none, offline }

/// P9 (17, 17b–17e). Returns true when the user taps Try again.
Future<bool?> showPurchaseResult(
  BuildContext context,
  WidgetRef ref,
  PurchaseResultKind kind,
) {
  final l10n = AppLocalizations.of(context);
  final entitlement = ref.read(entitlementProvider);
  return AppDialog.show<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      final text = dialogContext.appText;
      // No-purchases (none): no search/magnifier icon (Sabitha #93).
      final (IconData? icon, soft, strong, title, body) = switch (kind) {
        PurchaseResultKind.failed => (
          PhosphorIcons.creditCard(),
          colors.dangerSoft,
          colors.danger,
          l10n.p9FailedTitle,
          l10n.p9FailedBody,
        ),
        PurchaseResultKind.restored => (
          PhosphorIcons.crown(PhosphorIconsStyle.fill),
          colors.accentSoft,
          colors.gold,
          l10n.p9RestoredTitle,
          l10n.p9RestoredBody,
        ),
        PurchaseResultKind.pending => (
          PhosphorIcons.hourglassMedium(),
          colors.warnSoft,
          colors.warn,
          l10n.p9PendingTitle,
          l10n.p9PendingBody,
        ),
        PurchaseResultKind.none => (
          null,
          colors.surface2,
          colors.text2,
          l10n.p9NoneTitle,
          l10n.p9NoneBody,
        ),
        PurchaseResultKind.offline => (
          PhosphorIcons.wifiSlash(),
          colors.warnSoft,
          colors.warn,
          l10n.p9OfflineTitle,
          l10n.p9OfflineBody,
        ),
      };
      final expires = entitlement.expiresAt;
      final detail = switch (kind) {
        PurchaseResultKind.failed => l10n.p9FailedTip,
        PurchaseResultKind.restored =>
          expires == null
              ? l10n.p9RestoredLifetime
              : l10n.p9RestoredRenews(
                  l10n.proCardTitle,
                  DateFormat.yMMMd(l10n.localeName).format(expires),
                ),
        _ => null,
      };
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Icon(icon, color: strong, size: 28),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
          ],
          Text(title, textAlign: TextAlign.center, style: text.dialogTitle),
          const SizedBox(height: AppSpace.s8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: text.body.copyWith(color: colors.text2),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpace.s14),
            Container(
              padding: const EdgeInsets.all(AppSpace.s12),
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: text.caption.copyWith(color: colors.text),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s20),
          PrimaryButton(
            label: kind == PurchaseResultKind.failed ? l10n.tryAgain : l10n.ok,
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(kind == PurchaseResultKind.failed),
          ),
          if (kind == PurchaseResultKind.failed ||
              kind == PurchaseResultKind.none) ...[
            const SizedBox(height: AppSpace.s4),
            Center(
              child: TextLinkButton(
                label: l10n.contactSupport,
                muted: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                  contactSupport(context, ref, screen: 'purchase');
                },
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// Formats an amount in the store's currency (per-week, per-month).
String formatPrice(StorePlan plan, double amount, String localeName) {
  return NumberFormat.simpleCurrency(
    locale: localeName,
    name: plan.currencyCode,
  ).format(amount);
}
