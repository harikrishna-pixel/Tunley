import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';

/// Video frame or a music-note tile. Travels between screens as a `Hero`.
class MediaThumb extends StatelessWidget {
  const MediaThumb({
    super.key,
    required this.size,
    this.path,
    this.isVideo = true,
    this.heroTag,
    this.radius = AppRadius.chip,
    this.showPlay = false,
  });

  final double size;
  final String? path;
  final bool isVideo;
  final Object? heroTag;
  final double radius;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final file = path == null ? null : File(path!);
    final hasImage = file != null && file.existsSync();
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Widget child = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(file, fit: BoxFit.cover, cacheWidth: pixels)
            else
              ColoredBox(
                color: colors.accentSoft,
                child: Center(
                  child: PhosphorIcon(
                    isVideo
                        ? PhosphorIcons.filmSlate(PhosphorIconsStyle.fill)
                        : PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
                    color: colors.accentOnSoft,
                    size: size * 0.42,
                  ),
                ),
              ),
            if (showPlay && hasImage)
              Center(
                child: PhosphorIcon(
                  PhosphorIcons.play(PhosphorIconsStyle.fill),
                  color: colors.heroText,
                  size: size * 0.32,
                ),
              ),
          ],
        ),
      ),
    );
    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }
    return child;
  }
}

/// Source summary at the top of Convert: thumbnail, name, type, length, size.
class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.source});

  final SourceFile source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final info = source.info;
    final meta = source.isVideo
        ? l10n.sourceVideoMeta(
            Fmt.duration(info.durationSec),
            Fmt.bytes(info.bytes),
          )
        : l10n.sourceAudioMeta(
            Fmt.extension(source.name),
            Fmt.duration(info.durationSec),
            Fmt.bytes(info.bytes),
          );
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Row(
        children: [
          MediaThumb(
            size: 64,
            path: source.thumbnailPath,
            isVideo: source.isVideo,
            heroTag: 'thumb:${source.path}',
            showPlay: true,
          ),
          const SizedBox(width: AppSpace.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: text.caption.copyWith(color: context.colors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed footer above the home indicator with the screen's one primary action.
class ActionFooter extends StatelessWidget {
  const ActionFooter({super.key, required this.child, this.summary});

  final Widget child;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s8,
          AppSpace.screen,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (summary != null) ...[
              summary!,
              const SizedBox(height: AppSpace.s10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
