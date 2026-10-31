import 'package:flutter/material.dart';

import 'theme_context.dart';
import 'tokens.dart';

class TrialStep {
  const TrialStep({
    required this.icon,
    required this.title,
    required this.dayLabel,
  });

  final IconData icon;
  final String title;
  final String dayLabel;
}

class TrialTimeline extends StatelessWidget {
  const TrialTimeline({super.key, required this.steps});

  final List<TrialStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].icon,
                          size: 16,
                          color: colors.accentOnSoft,
                        ),
                      ),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(width: 2, color: colors.border),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : AppSpace.s16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].dayLabel,
                          style: context.appText.caption.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(steps[i].title, style: context.appText.body),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
