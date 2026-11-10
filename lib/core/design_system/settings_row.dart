import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'theme_context.dart';
import 'tokens.dart';

/// Icon, label, optional value and a chevron. Lives inside a `ListGroup`.
/// The chevron sits in a fixed trailing slot so every row lines up.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.valueHighlight = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool valueHighlight;
  final Color? iconColor;
  final VoidCallback? onTap;

  static const _chevronSlot = 22.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s20,
              vertical: AppSpace.s10,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Icon(icon, size: 22, color: iconColor ?? colors.text),
                ),
                const SizedBox(width: AppSpace.s14),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.subhead.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(width: AppSpace.s8),
                        Flexible(
                          child: Text(
                            value!,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.caption.copyWith(
                              color: valueHighlight
                                  ? colors.success
                                  : colors.text2,
                              fontWeight:
                                  valueHighlight ? FontWeight.w800 : null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s6),
                SizedBox(
                  width: _chevronSlot,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PhosphorIcon(
                      PhosphorIcons.caretRight(),
                      size: 18,
                      color: colors.text3,
                    ),
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
