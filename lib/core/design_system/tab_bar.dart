import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

/// Bottom tab bar on phone widths; a vertical rail in wide windows (iPhone
/// Duo unfolded), like the system tab bar built with the iOS 27.1 SDK.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.index,
    required this.onTap,
    this.vertical = false,
    this.railOnRight = false,
  });

  final int index;
  final ValueChanged<int> onTap;
  final bool vertical;

  /// The rail's edge; its divider faces the content.
  final bool railOnRight;

  static const railWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final padding = MediaQuery.paddingOf(context);
    final items = [
      (PhosphorIcons.house, l10n.tabHome),
      (PhosphorIcons.folders, l10n.tabFiles),
      (PhosphorIcons.gearSix, l10n.tabSettings),
    ];
    final buttons = [
      for (var i = 0; i < items.length; i++)
        _TabButton(
          icon: items[i].$1,
          label: items[i].$2,
          selected: index == i,
          onTap: () => onTap(i),
        ),
    ];
    final divider = BorderSide(color: colors.divider);
    // Like UIKit tab bars, labels grow only a little with Dynamic Type; the
    // bar grows with them instead of clipping.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppBlur.overlay,
            sigmaY: AppBlur.overlay,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tab,
              border: vertical
                  ? Border(
                      left: railOnRight ? divider : BorderSide.none,
                      right: railOnRight ? BorderSide.none : divider,
                    )
                  : Border(top: divider),
            ),
            child: vertical
                ? Padding(
                    padding: EdgeInsets.only(
                      top: padding.top + AppSpace.s24,
                      bottom: padding.bottom,
                      left: railOnRight ? 0 : padding.left,
                      right: railOnRight ? padding.right : 0,
                    ),
                    child: SizedBox(
                      width: railWidth,
                      child: Column(
                        children: [
                          for (final button in buttons)
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 72),
                              child: button,
                            ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                      bottom: padding.bottom,
                      left: padding.left,
                      right: padding.right,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final button in buttons)
                              Expanded(child: button),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PhosphorIconData Function([PhosphorIconsStyle style]) icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.link : colors.text3;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                icon(
                  selected
                      ? PhosphorIconsStyle.fill
                      : PhosphorIconsStyle.regular,
                ),
                size: 24,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.appText.micro.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
