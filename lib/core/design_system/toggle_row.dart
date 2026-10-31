import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme_context.dart';
import 'tokens.dart';

/// Title, optional caption and a switch. The whole row is the tap target.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s20,
            vertical: AppSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.appText.subhead),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.appText.caption.copyWith(
                          color: colors.text3,
                        ),
                      ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: colors.accent,
                inactiveTrackColor: colors.surface2,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact pill with a label and a switch, used inside the ringtone card.
class TogglePill extends StatelessWidget {
  const TogglePill({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: Material(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s14,
              AppSpace.s6,
              AppSpace.s8,
              AppSpace.s6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.appText.caption.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: value,
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.border,
                    onChanged: onChanged,
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
