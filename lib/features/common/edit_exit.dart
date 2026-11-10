import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';

/// Confirm before leaving Convert / Trim with unsaved edits.
Future<bool> confirmDiscardEdits(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await AppAlert.show<bool>(
    context: context,
    title: l10n.editExitTitle,
    body: l10n.editExitBody,
    actions: [
      AlertAction(
        l10n.editExitConfirm,
        true,
        tone: AlertTone.destructive,
      ),
      AlertAction(l10n.editExitContinue, false),
    ],
  );
  return result == true;
}
