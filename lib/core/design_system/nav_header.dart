import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

enum NavLeading { back, close, none }

/// Centered title with a 44 pt leading button and an optional trailing widget.
class NavHeader extends StatelessWidget {
  const NavHeader({
    super.key,
    required this.title,
    this.leading = NavLeading.back,
    this.onLeading,
    this.trailing,
  });

  final String title;
  final NavLeading leading;
  final VoidCallback? onLeading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final button = switch (leading) {
      NavLeading.back => _NavButton(
        icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
        label: l10n.back,
        onTap: onLeading ?? () => Navigator.of(context).maybePop(),
      ),
      NavLeading.close => _NavButton(
        icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
        label: l10n.close,
        onTap: onLeading ?? () => Navigator.of(context).maybePop(),
      ),
      NavLeading.none => const SizedBox(width: 44),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s12,
        AppSpace.s8,
        AppSpace.s12,
        AppSpace.s8,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            button,
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appText.navTitle.copyWith(color: colors.text),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 1,
                child: trailing ?? const SizedBox(width: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: context.colors.text),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Text(
        text,
        style: context.appText.caption.copyWith(
          color: context.colors.text2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
