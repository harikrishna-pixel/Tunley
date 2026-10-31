import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'theme_context.dart';
import 'tokens.dart';

class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.message,
    this.tone = StatusTone.success,
  });

  final String message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      StatusTone.success => (colors.successSoft, colors.success),
      StatusTone.warn => (colors.warnSoft, colors.warn),
      StatusTone.danger => (colors.dangerSoft, colors.danger),
      StatusTone.info => (colors.accentSoft, colors.accentOnSoft),
    };
    final icon = switch (tone) {
      StatusTone.success => PhosphorIcons.shieldCheck(),
      StatusTone.warn => PhosphorIcons.warning(),
      StatusTone.danger => PhosphorIcons.warningCircle(),
      StatusTone.info => PhosphorIcons.info(),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.status),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s14,
          vertical: AppSpace.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: PhosphorIcon(icon, color: foreground, size: 18),
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Text(
                message,
                style: context.appText.caption.copyWith(
                  color: foreground,
                  fontWeight: tone == StatusTone.success
                      ? FontWeight.w700
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusTone { success, warn, danger, info }
