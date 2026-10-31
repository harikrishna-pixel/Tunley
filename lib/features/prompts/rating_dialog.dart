import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/rating_rules.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_screen.dart';
import 'prompt_widgets.dart';

/// Rating (26) on a fresh Result, per `05` §5. Returns whether it was shown.
Future<bool> maybeAskForRating(
  BuildContext context,
  WidgetRef ref, {
  required bool ringtone,
}) async {
  final config = ref.read(appConfigProvider).rating;
  final usage = ref.read(usageStoreProvider);
  bool due() {
    final session = ref.read(paywallProvider);
    return !session.errorThisSession && !session.paywallThisSession;
  }

  if (!due()) return false;
  final memory = await usage.rating();
  final request = RatingRequest(
    ringtonesSaved: await usage.ringtonesSaved(),
    successfulConversions: await usage.lifetimeConversions(),
    timesAsked: memory.times,
    lastAskedAt: memory.lastAt,
    now: DateTime.now(),
    errorThisSession: ref.read(paywallProvider).errorThisSession,
    paywallThisSession: ref.read(paywallProvider).paywallThisSession,
    afterRingtones: config.afterRingtones,
    afterConversions: config.afterConversions,
    maxTimes: config.maxTimes,
    minDaysBetween: config.minDaysBetween,
  );
  if (!RatingRules.shouldAsk(request)) return false;
  await Future<void>.delayed(Duration(milliseconds: config.delayMs));
  if (!context.mounted || !due()) return false;
  await usage.recordRatingAsked(DateTime.now());
  if (!context.mounted) return false;
  final analytics = ref.read(analyticsProvider);
  analytics.ratingPromptShown(
    trigger: request.ringtonesSaved >= request.afterRingtones
        ? 'ringtones_${request.afterRingtones}'
        : 'conversions_${request.afterConversions}',
    timesShown: memory.times + 1,
  );
  final stars = await AppDialog.show<int>(
    context: context,
    builder: (_) => RatingDialog(ringtone: ringtone),
  );
  analytics.ratingPromptAnswered(
    stars: stars ?? 0,
    routedTo: stars == null
        ? 'none'
        : stars >= 4
        ? 'app_store'
        : 'feedback',
  );
  if (stars == null || !context.mounted) return true;
  if (stars >= 4) {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      final id = ref.read(appConfigProvider).appStoreId;
      if (id != null) await review.openStoreListing(appStoreId: id);
    }
  } else if (context.mounted) {
    await contactSupport(
      context,
      ref,
      subject: AppLocalizations.of(context).feedbackSubject,
    );
  }
  return true;
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.ringtone = true});

  final bool ringtone;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandTile()),
        const SizedBox(height: AppSpace.s16),
        Semantics(
          header: true,
          child: Text(
            widget.ringtone ? l10n.ratingTitleRingtone : l10n.ratingTitleAudio,
            textAlign: TextAlign.center,
            style: text.dialogTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          l10n.ratingBody,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var n = 1; n <= 5; n++)
              Semantics(
                button: true,
                selected: n == _stars,
                label: l10n.ratingStars(n),
                excludeSemantics: true,
                child: InkResponse(
                  onTap: () => setState(() => _stars = n),
                  radius: 24,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Opacity(
                      opacity: n <= _stars ? 1 : 0.25,
                      child: PhosphorIcon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        color: colors.gold,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: _stars >= 4 ? l10n.ratingRate : l10n.ratingFeedback,
          onPressed: () => Navigator.of(context).pop(_stars),
        ),
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.notNow,
            muted: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
