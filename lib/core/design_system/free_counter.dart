import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

class FreeCounter extends StatelessWidget {
  const FreeCounter({super.key, required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final empty = remaining <= 0;
    final color = empty ? colors.warn : colors.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.s6),
        Text(
          AppLocalizations.of(context).freeCounter(remaining, total),
          style: context.appText.footnote.copyWith(
            color: empty ? colors.warn : colors.text2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
