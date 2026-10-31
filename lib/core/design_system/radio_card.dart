import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_context.dart';
import 'tokens.dart';

class RadioCard extends StatelessWidget {
  const RadioCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.sizeLabel,
  });

  final String title;
  final String? subtitle;
  final String? sizeLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                RadioMark(selected: selected),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.appText.subhead),
                      if (subtitle != null)
                        Text(subtitle!, style: context.appText.caption),
                    ],
                  ),
                ),
                if (sizeLabel != null)
                  Text(
                    sizeLabel!,
                    style: context.appText.subhead.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.success,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RadioMark extends StatelessWidget {
  const RadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: AppMotion.of(
        const Duration(milliseconds: 150),
        MediaQuery.disableAnimationsOf(context),
      ),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accent : Colors.transparent,
        border: Border.all(
          color: selected ? colors.accent : colors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
