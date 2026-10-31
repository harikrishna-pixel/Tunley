import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.title,
    required this.meta,
    required this.elapsedLabel,
    required this.durationLabel,
    required this.peaks,
    required this.played,
    required this.playing,
    required this.onPlay,
    this.thumbnailPath,
  });

  final String? thumbnailPath;
  final String title;
  final String meta;
  final String elapsedLabel;
  final String durationLabel;
  final List<double> peaks;
  final double played;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    color: const Color(0x24FFFFFF),
                    child:
                        thumbnailPath != null &&
                            File(thumbnailPath!).existsSync()
                        ? Image.file(
                            File(thumbnailPath!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            cacheWidth: 168,
                          )
                        : PhosphorIcon(
                            PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
                            color: colors.heroText,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appText.subhead.copyWith(
                          color: colors.heroText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        meta,
                        style: context.appText.footnote.copyWith(
                          color: const Color(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Material(
                  color: colors.heroText,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPlay,
                    child: Semantics(
                      button: true,
                      label: playing ? l10n.pause : l10n.play,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: PhosphorIcon(
                          playing
                              ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                              : PhosphorIcons.play(PhosphorIconsStyle.fill),
                          color: colors.heroButtonText,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            SizedBox(
              height: 36,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PlayerBarsPainter(peaks: peaks, played: played),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  elapsedLabel,
                  style: context.appText.footnote.copyWith(
                    color: colors.heroText,
                  ),
                ),
                Text(
                  durationLabel,
                  style: context.appText.footnote.copyWith(
                    color: const Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBarsPainter extends CustomPainter {
  _PlayerBarsPainter({required this.peaks, required this.played});

  final List<double> peaks;
  final double played;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty || size.width <= 0) {
      return;
    }
    const gap = 2.0;
    final barWidth = (size.width - gap * (peaks.length - 1)) / peaks.length;
    final playedPaint = Paint()..color = const Color(0xFFFFFFFF);
    final restPaint = Paint()..color = const Color(0x59FFFFFF);
    for (var i = 0; i < peaks.length; i++) {
      final height = (peaks[i].clamp(0.08, 1) * size.height);
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
        const Radius.circular(2),
      );
      final fraction = (i + 1) / peaks.length;
      canvas.drawRRect(rect, fraction <= played ? playedPaint : restPaint);
    }
  }

  @override
  bool shouldRepaint(_PlayerBarsPainter oldDelegate) {
    return oldDelegate.played != played || oldDelegate.peaks != peaks;
  }
}
