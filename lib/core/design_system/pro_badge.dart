import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'app_text.dart';
import 'theme_context.dart';
import 'tokens.dart';

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.proBadgeBg,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          AppLocalizations.of(context).proBadge,
          style: TextStyle(
            fontFamily: AppText.family,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: colors.proBadgeText,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class ProChip extends StatelessWidget {
  const ProChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.proChip),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s10,
          vertical: AppSpace.s6,
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
            Text(
              AppLocalizations.of(context).proChip,
              style: context.appText.caption.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
