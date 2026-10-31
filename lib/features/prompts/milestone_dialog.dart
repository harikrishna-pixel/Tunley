import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/milestone_rules.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import 'prompt_widgets.dart';
import 'share_card_sheet.dart';

/// Milestones (30) on a fresh Result. Returns whether one was shown.
Future<bool> maybeShowMilestone(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item,
) async {
  final usage = ref.read(usageStoreProvider);
  final milestone = MilestoneRules.due(
    thresholds: ref.read(appConfigProvider).milestones,
    ringtonesSaved: await usage.ringtonesSaved(),
    lifetimeFiles: await usage.lifetimeConversions(),
    justMadeRingtone: item.isTone,
    shown: await usage.milestonesShown(),
  );
  if (milestone == null || !context.mounted) return false;
  await usage.markMilestone(milestone.key);
  if (!context.mounted) return false;
  ref
      .read(analyticsProvider)
      .milestoneReached(
        name: switch (milestone) {
          FirstRingtoneMilestone() => 'first_ringtone',
          FilesMilestone(:final files) => 'files_$files',
        },
      );
  final share = await AppDialog.show<bool>(
    context: context,
    builder: (_) =>
        MilestoneDialog(milestone: milestone, ringtone: item.isTone),
  );
  if (share == true && context.mounted) {
    await showShareCard(context, ref, item, entry: 'milestone');
  }
  return true;
}

class MilestoneDialog extends StatelessWidget {
  const MilestoneDialog({
    super.key,
    required this.milestone,
    required this.ringtone,
  });

  final Milestone milestone;
  final bool ringtone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final (title, body) = switch (milestone) {
      FirstRingtoneMilestone() => (
        l10n.milestoneFirstRingtone,
        l10n.milestoneFirstRingtoneBody,
      ),
      FilesMilestone(:final files) => (
        l10n.milestoneFiles(files),
        l10n.milestoneFilesBody(files),
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SoftIconCircle(
            icon: milestone is FirstRingtoneMilestone
                ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill)
                : PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
            badge: true,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(
          l10n.milestoneEyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: text.micro.copyWith(color: colors.link),
        ),
        const SizedBox(height: AppSpace.s6),
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
          body,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(
          label: ringtone
              ? l10n.milestoneShareRingtone
              : l10n.milestoneShareFile,
          icon: PhosphorIcons.export(),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.close,
            muted: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
