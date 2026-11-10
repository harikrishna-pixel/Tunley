import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';

/// Half-width of a trim handle — kept clear of the view edges so handles
/// stay fully visible at 0% / 100%.
const _handleInset = 8.0;

/// Selectable waveform. Peaks are 0..1. [start] and [end] are fractions.
class WaveformView extends StatefulWidget {
  const WaveformView({
    super.key,
    required this.peaks,
    required this.start,
    required this.end,
    this.onChanged,
    this.playhead,
    this.height = 72,
    this.maxSpan = 1,
  });

  final double height;

  /// Longest allowed selection as a fraction of the file (ringtones: 30 s).
  final double maxSpan;
  final List<double> peaks;
  final double start;
  final double end;
  final double? playhead;
  final void Function(double start, double end)? onChanged;

  @override
  State<WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<WaveformView> {
  _DragTarget? _drag;

  double _usable(double width) => (width - _handleInset * 2).clamp(1.0, width);

  double _xFor(double fraction, double width) =>
      _handleInset + fraction.clamp(0.0, 1.0) * _usable(width);

  void _update(double dx, double width) {
    if (widget.onChanged == null || _drag == null || width <= 0) {
      return;
    }
    final delta = dx / _usable(width);
    var start = widget.start;
    var end = widget.end;
    switch (_drag!) {
      case _DragTarget.start:
        start = (start + delta).clamp(
          (end - widget.maxSpan).clamp(0.0, 1.0),
          end - 0.02,
        );
      case _DragTarget.end:
        end = (end + delta).clamp(
          start + 0.02,
          (start + widget.maxSpan).clamp(0.0, 1.0),
        );
      case _DragTarget.range:
        final span = end - start;
        start = (start + delta).clamp(0.0, 1 - span);
        end = start + span;
    }
    widget.onChanged!(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          label: AppLocalizations.of(context).waveformRange,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              _drag = _hit(details.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (details) {
              _update(details.delta.dx, width);
            },
            onHorizontalDragEnd: (_) => _drag = null,
            child: SizedBox(
              height: widget.height,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WaveformPainter(
                    peaks: widget.peaks,
                    start: widget.start,
                    end: widget.end,
                    playhead: widget.playhead,
                    selected: colors.accent,
                    outside: colors.border,
                    handle: colors.accent,
                    playheadColor: colors.text,
                    grip: colors.accentText,
                    inset: _handleInset,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _DragTarget _hit(double x, double width) {
    final startX = _xFor(widget.start, width);
    final endX = _xFor(widget.end, width);
    if ((x - startX).abs() < 22) {
      return _DragTarget.start;
    }
    if ((x - endX).abs() < 22) {
      return _DragTarget.end;
    }
    return _DragTarget.range;
  }
}

enum _DragTarget { start, end, range }

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.peaks,
    required this.start,
    required this.end,
    required this.playhead,
    required this.selected,
    required this.outside,
    required this.handle,
    required this.playheadColor,
    required this.grip,
    required this.inset,
  });

  final List<double> peaks;
  final double start;
  final double end;
  final double? playhead;
  final Color selected;
  final Color outside;
  final Color handle;
  final Color playheadColor;
  final Color grip;
  final double inset;

  double _usable(Size size) => (size.width - inset * 2).clamp(1.0, size.width);

  double _xFor(double fraction, Size size) =>
      inset + fraction.clamp(0.0, 1.0) * _usable(size);

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      return;
    }
    const bar = 3.0;
    const gap = 2.0;
    final count = peaks.length;
    final usable = _usable(size);
    final total = count * bar + (count - 1) * gap;
    final scale = total > usable ? usable / total : 1.0;
    final barWidth = bar * scale;
    final gapWidth = gap * scale;
    final selectedPaint = Paint()..color = selected;
    final outsidePaint = Paint()..color = outside;
    for (var i = 0; i < count; i++) {
      final left = inset + i * (barWidth + gapWidth);
      final centerFrac = ((left - inset) + barWidth / 2) / usable;
      final height = (8 + peaks[i].clamp(0, 1) * (size.height - 16)).toDouble();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
        const Radius.circular(1.5),
      );
      final inside = centerFrac >= start && centerFrac <= end;
      canvas.drawRRect(rect, inside ? selectedPaint : outsidePaint);
    }
    _handle(canvas, size, _xFor(start, size));
    _handle(canvas, size, _xFor(end, size));
    if (playhead != null) {
      final x = _xFor(playhead!, size);
      canvas.drawRect(
        Rect.fromLTWH(x - 1, 0, 2, size.height),
        Paint()..color = playheadColor,
      );
    }
  }

  void _handle(Canvas canvas, Size size, double x) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, size.height / 2),
        width: 14,
        height: 56,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(rect, Paint()..color = handle);
    final gripPaint = Paint()
      ..color = grip
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final midY = size.height / 2;
    for (final dx in [-2.0, 2.0]) {
      canvas.drawLine(
        Offset(x + dx, midY - 8),
        Offset(x + dx, midY + 8),
        gripPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.playhead != playhead ||
        oldDelegate.peaks != peaks ||
        oldDelegate.selected != selected ||
        oldDelegate.inset != inset;
  }
}
