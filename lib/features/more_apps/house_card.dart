import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../core/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import 'more_apps_screen.dart';

/// Small, dismissible Marberx card on Result (09d). Information, not a pop-up.
class HouseCard extends StatelessWidget {
  const HouseCard({
    super.key,
    required this.app,
    required this.body,
    required this.onView,
    required this.onHide,
  });

  final MoreApp app;
  final String body;
  final VoidCallback onView;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s14,
        AppSpace.s4,
        AppSpace.s14,
      ),
      child: Row(
        children: [
          MarberxIcon(id: app.id, size: 46),
          const SizedBox(width: AppSpace.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.houseCardEyebrow,
                  style: text.footnote.copyWith(color: colors.text2),
                ),
                Text(
                  app.name,
                  style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(body, style: text.caption.copyWith(color: colors.text2)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          if (app.hasStoreId)
            Material(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.proChip),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.proChip),
                onTap: onView,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s14,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        l10n.houseCardView,
                        style: text.subhead.copyWith(
                          color: colors.accentOnSoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.houseCardHide,
            onPressed: onHide,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: PhosphorIcon(
              PhosphorIcons.x(PhosphorIconsStyle.bold),
              color: colors.text3,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
