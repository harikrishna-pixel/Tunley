import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../app/analytics_sync.dart';
import '../../l10n/app_localizations.dart';
import '../paywall/checkout.dart';
import 'prompt_widgets.dart';

enum NotifyReason { batch, trial }

const _denied = 'denied';

/// Notification pre-prompt (27) before the system prompt. Once per reason;
/// if iOS permission is denied, never asked again (`05` §5).
/// Returns whether notifications are allowed afterwards.
Future<bool> askNotifications(
  BuildContext context,
  WidgetRef ref,
  NotifyReason reason,
) async {
  final reminder = ref.read(trialReminderProvider);
  final usage = ref.read(usageStoreProvider);
  if (await reminder.notificationsAllowed()) return true;
  final used = await usage.notifyPrompts();
  if (used.contains(_denied) || used.contains(reason.name)) return false;
  if (!context.mounted) return false;
  await usage.markNotifyPrompt(reason.name);
  if (!context.mounted) return false;
  final analytics = ref.read(analyticsProvider);
  analytics.notificationPromptShown(context: reason.name);
  final turnOn = await AppBottomSheet.show<bool>(
    context: context,
    builder: (_) => NotificationPrompt(reason: reason),
  );
  if (turnOn != true) return false;
  analytics.permissionRequested();
  final allowed = await reminder.requestPermission();
  analytics.permissionResult(granted: allowed);
  ref.read(analyticsSyncProvider).notificationsEnabled(allowed);
  if (!allowed) await usage.markNotifyPrompt(_denied);
  return allowed;
}

class NotificationPrompt extends StatelessWidget {
  const NotificationPrompt({super.key, required this.reason});

  final NotifyReason reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final trial = reason == NotifyReason.trial;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                const BrandTile(size: 38),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.notifyPreviewApp,
                              style: text.footnote.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            l10n.notifyPreviewNow,
                            style: text.footnote.copyWith(color: colors.text3),
                          ),
                        ],
                      ),
                      Text(
                        trial
                            ? l10n.notifyTrialPreviewBody
                            : l10n.notifyPreviewBody,
                        style: text.caption.copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s20),
        Semantics(
          header: true,
          child: Text(
            trial ? l10n.notifyTrialTitle : l10n.notifyTitle,
            textAlign: TextAlign.center,
            style: text.dialogTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          trial ? l10n.notifyTrialBody : l10n.notifyBody,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(
          label: l10n.notifyTurnOn,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.notNow,
            muted: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
