import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_context.dart';
import 'tokens.dart';

class SegmentedItem<T> {
  const SegmentedItem({required this.value, required this.label});

  final T value;
  final String label;
}

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: _Segment(
                  label: item.label,
                  selected: item.value == value,
                  onTap: () {
                    if (item.value == value) {
                      return;
                    }
                    HapticFeedback.selectionClick();
                    onChanged(item.value);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: AnimatedContainer(
            duration: AppMotion.of(
              const Duration(milliseconds: 180),
              MediaQuery.disableAnimationsOf(context),
            ),
            curve: Curves.easeOut,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : colors.surface.withAlpha(0),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              boxShadow: selected ? colors.shadow : null,
            ),
            child: Text(
              label,
              style: context.appText.caption.copyWith(
                color: selected ? colors.text : colors.text3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
