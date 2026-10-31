import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_screen.dart';

/// Same questions as O2/O3. Changes apply immediately.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: l10n.prefsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s8,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  SectionLabel(l10n.prefsWhat),
                  for (final (goal, label) in [
                    (UserGoal.ringtones, l10n.prefsGoalRingtones),
                    (UserGoal.mp3FromVideos, l10n.prefsGoalMp3),
                    (UserGoal.convertFiles, l10n.prefsGoalConvert),
                  ]) ...[
                    ChoiceCard(
                      title: label,
                      selected: prefs.goal == goal,
                      onTap: () {
                        notifier.setGoal(goal);
                        ref
                            .read(analyticsProvider)
                            .preferencesChanged(
                              field: 'goal',
                              value: AnalyticsValues.goal(goal),
                            );
                      },
                    ),
                    const SizedBox(height: AppSpace.s10),
                  ],
                  const SizedBox(height: AppSpace.s8),
                  SectionLabel(l10n.prefsHowOften),
                  Row(
                    children: [
                      for (final (frequency, label) in [
                        (UsageFrequency.everyDay, l10n.prefsDaily),
                        (UsageFrequency.fewTimesAWeek, l10n.prefsWeekly),
                        (UsageFrequency.onceInAWhile, l10n.prefsRarely),
                      ]) ...[
                        if (frequency != UsageFrequency.everyDay)
                          const SizedBox(width: AppSpace.s8),
                        Expanded(
                          child: FormatChip(
                            label: label,
                            selected: prefs.frequency == frequency,
                            onTap: () {
                              notifier.setFrequency(frequency);
                              ref
                                  .read(analyticsProvider)
                                  .preferencesChanged(
                                    field: 'frequency',
                                    value: AnalyticsValues.frequency(frequency),
                                  );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpace.s20),
                  StatusBox(message: l10n.prefsInfo, tone: StatusTone.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
