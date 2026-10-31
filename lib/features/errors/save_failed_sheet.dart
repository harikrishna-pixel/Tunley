import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../core/design_system/design_system.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';

enum SaveChoice { saveOnIphone, retry, chooseFolder, share }

/// E5 (36) and folder-not-found (36b). The file is already in the library,
/// so nothing needs to be converted again.
abstract final class SaveFailedSheet {
  static Future<SaveChoice?> show(
    BuildContext context, {
    required String format,
    required bool folderGone,
    bool destinationFull = false,
  }) async {
    final analytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(analyticsProvider);
    final type = folderGone ? 'stale_folder' : 'save_failed';
    analytics.errorShown(type: type, code: 'AUD-IO-05');
    final choice = await AppBottomSheet.show<SaveChoice>(
      context: context,
      builder: (sheetContext) => _SaveFailedBody(
        format: format,
        folderGone: folderGone,
        destinationFull: destinationFull,
      ),
    );
    if (choice != null) {
      analytics.errorRecoveryAction(
        type: type,
        action: switch (choice) {
          SaveChoice.saveOnIphone => 'save_on_iphone',
          SaveChoice.retry => 'retry',
          SaveChoice.chooseFolder => 'choose_folder',
          SaveChoice.share => 'share_instead',
        },
      );
    }
    return choice;
  }
}

class _SaveFailedBody extends ConsumerWidget {
  const _SaveFailedBody({
    required this.format,
    required this.folderGone,
    required this.destinationFull,
  });

  final String format;
  final bool folderGone;
  final bool destinationFull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final days = ref.watch(appConfigProvider).pendingKeepDays;
    void pick(SaveChoice choice) => Navigator.of(context).pop(choice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: PhosphorIcon(
                PhosphorIcons.warningCircle(),
                color: colors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpace.s14),
            Expanded(
              child: Text(
                folderGone ? l10n.e5bTitle : l10n.e5Title,
                style: text.dialogTitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s14),
        Text(
          folderGone
              ? l10n.e5bBody
              : destinationFull
              ? l10n.e5BodyFull
              : l10n.e5Body,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s16),
        Container(
          padding: const EdgeInsets.all(AppSpace.s14),
          decoration: BoxDecoration(
            color: colors.successSoft,
            borderRadius: BorderRadius.circular(AppRadius.status),
          ),
          child: Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: colors.success,
                size: 24,
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.e5Safe(format),
                      style: text.subhead.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.e5SafeDetail(days),
                      style: text.footnote.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: folderGone ? l10n.chooseFolderAgain : l10n.saveOnIphoneInstead,
          onPressed: () => pick(
            folderGone ? SaveChoice.chooseFolder : SaveChoice.saveOnIphone,
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.s16,
          children: [
            TextLinkButton(
              label: folderGone ? l10n.saveOnIphone : l10n.tryAgain,
              onPressed: () =>
                  pick(folderGone ? SaveChoice.saveOnIphone : SaveChoice.retry),
            ),
            TextLinkButton(
              label: l10n.shareInstead,
              onPressed: () => pick(SaveChoice.share),
            ),
          ],
        ),
      ],
    );
  }
}
