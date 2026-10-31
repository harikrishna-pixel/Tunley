import 'package:flutter/material.dart';

import 'pro_badge.dart';
import 'theme_context.dart';
import 'tokens.dart';

class FormatChip extends StatelessWidget {
  const FormatChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showProBadge = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showProBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.accentSoft : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  label,
                  style: context.appText.caption.copyWith(
                    color: selected ? colors.accentOnSoft : colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showProBadge)
                const Positioned(top: -6, right: 4, child: ProBadge()),
            ],
          ),
        ),
      ),
    );
  }
}
