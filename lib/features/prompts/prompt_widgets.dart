import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/design_system/design_system.dart';

/// Rounded brand tile used at the top of prompts (26, 29, 27 preview).
class BrandTile extends StatelessWidget {
  const BrandTile({super.key, this.size = 64, this.icon});

  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: colors.heroGradient,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: PhosphorIcon(
          icon ?? PhosphorIcons.waveform(PhosphorIconsStyle.bold),
          color: colors.heroText,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Soft circular icon (Update download, Milestone bell).
class SoftIconCircle extends StatelessWidget {
  const SoftIconCircle({super.key, required this.icon, this.badge = false});

  final IconData icon;

  /// Small success check at the bottom right (Milestone).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.accentOnSoft, size: 34),
            ),
            if (badge)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 3),
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: colors.accentText,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
