import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/rules/update_rules.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import 'prompt_widgets.dart';

/// Update (29) over Home when config recommends a newer version. Once per
/// version. Returns whether it was shown.
Future<bool> maybeShowUpdate(BuildContext context, WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  final usage = ref.read(usageStoreProvider);
  final info = await ref.read(audioEngineProvider).appInfo();
  final show = UpdateRules.shouldShow(
    current: info.version,
    latest: config.update.latest,
    minRecommended: config.update.minRecommended,
    shownForVersion: await usage.updateShownVersion(),
  );
  if (!show || !context.mounted) return false;
  await usage.markUpdateShown(config.update.latest);
  if (!context.mounted) return false;
  final analytics = ref.read(analyticsProvider);
  analytics.updatePromptShown(version: config.update.latest);
  final update = await AppDialog.show<bool>(
    context: context,
    builder: (_) =>
        UpdateDialog(version: config.update.latest, notes: config.update.notes),
  );
  final url = config.appStoreUrl;
  if (update == true) analytics.updateTapped(version: config.update.latest);
  if (update == true && url != null) {
    await ref.read(audioEngineProvider).openUrl(url);
  }
  return true;
}

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.version, required this.notes});

  final String version;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final bullets = notes.isEmpty ? [l10n.updateDefaultNote] : notes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SoftIconCircle(
            icon: PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold),
          ),
        ),
        const SizedBox(height: AppSpace.s14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s10,
              vertical: AppSpace.s4,
            ),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.proChip),
            ),
            child: Text(
              l10n.updateVersion(version),
              style: text.footnote.copyWith(
                color: colors.accentOnSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s10),
        Semantics(
          header: true,
          child: Text(
            l10n.updateTitle,
            textAlign: TextAlign.center,
            style: text.dialogTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s14),
        for (final note in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: colors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpace.s10),
                Expanded(child: Text(note, style: text.body)),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.s8),
        PrimaryButton(
          label: l10n.updateNow,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpace.s4),
        Center(
          child: TextLinkButton(
            label: l10n.updateLater,
            muted: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
