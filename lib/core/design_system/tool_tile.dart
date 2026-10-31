import 'package:flutter/material.dart';

import 'pro_badge.dart';
import 'theme_context.dart';
import 'tokens.dart';

class ToolTile extends StatelessWidget {
  const ToolTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showProBadge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showProBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 19, color: colors.accentOnSoft),
                    ),
                    const SizedBox(height: AppSpace.s10),
                    Text(
                      label,
                      style: context.appText.caption.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                if (showProBadge)
                  const Positioned(top: -4, right: -4, child: ProBadge()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
