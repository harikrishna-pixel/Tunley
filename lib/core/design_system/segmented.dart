import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_context.dart';
import 'tokens.dart';

class SegmentedItem<T> {
  const SegmentedItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// iOS-style segmented control with one sliding pill (no per-segment shadow
/// flicker when the selection moves).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentedItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = AppMotion.of(const Duration(milliseconds: 220), reduce);
    final index = items.indexWhere((item) => item.value == value).clamp(0, items.length - 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / items.length;
            return SizedBox(
              height: 36,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: segmentWidth * index,
                    top: 0,
                    width: segmentWidth,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        // No shadow — avoids flicker while the pill slides.
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final item in items)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: item.value == value,
                            label: item.label,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (item.value == value) return;
                                  HapticFeedback.selectionClick();
                                  onChanged(item.value);
                                },
                                borderRadius: BorderRadius.circular(
                                  AppRadius.chip,
                                ),
                                child: SizedBox(
                                  height: 36,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: duration,
                                      curve: Curves.easeOut,
                                      style: context.appText.caption.copyWith(
                                        color: item.value == value
                                            ? colors.text
                                            : colors.text3,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
