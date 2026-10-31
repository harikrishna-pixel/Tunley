import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../common/share_tracking.dart';
import '../../l10n/app_localizations.dart';

/// Share card (31): a branded card rendered to an image and shared with the
/// file through the system share sheet. Nothing is uploaded by Tunely.
Future<void> showShareCard(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item, {
  required String entry,
}) {
  ref.read(analyticsProvider).shareCardOpened(entry: entry);
  return AppBottomSheet.show<void>(
    context: context,
    builder: (_) => ShareCardSheet(item: item),
  );
}

class ShareCardSheet extends ConsumerStatefulWidget {
  const ShareCardSheet({super.key, required this.item});

  final LibraryItem item;

  @override
  ConsumerState<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends ConsumerState<ShareCardSheet> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<XFile?> _renderCard() async {
    final boundary =
        _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return null;
    final dir = await Directory.systemTemp.createTemp('tunely_card');
    final file = File('${dir.path}/Tunely.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return XFile(file.path, mimeType: 'image/png');
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(libraryRepositoryProvider);
    try {
      final card = await _renderCard();
      final url = ref.read(appConfigProvider).appStoreUrl;
      await shareAndTrack(
        ref,
        format: widget.item.format,
        screen: 'share_card',
        ShareParams(
          files: [?card, XFile(repo.absolutePath(widget.item))],
          text: url == null ? l10n.shareCardText : '${l10n.shareCardText} $url',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    TunelyToast.show(context, message: AppLocalizations.of(context).linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final item = widget.item;
    final url = ref.watch(appConfigProvider).appStoreUrl;
    final repo = ref.watch(libraryRepositoryProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            item.isTone ? l10n.shareCardTitleRingtone : l10n.shareCardTitleFile,
            textAlign: TextAlign.center,
            style: text.dialogTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Center(
          child: RepaintBoundary(
            key: _card,
            child: ShareCard(
              title: Fmt.baseName(item.name),
              meta: item.isTone
                  ? l10n.shareCardMetaRingtone(Fmt.duration(item.durationSec))
                  : l10n.shareCardMetaFile(
                      item.format.toUpperCase(),
                      Fmt.duration(item.durationSec),
                    ),
              thumbnailPath: repo.thumbnailPath(item),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ShareAction(
              icon: PhosphorIcons.export(),
              label: l10n.shareAirDrop,
              onTap: _busy ? null : _share,
            ),
            _ShareAction(
              icon: PhosphorIcons.chatCircle(),
              label: l10n.shareMessages,
              onTap: _busy ? null : _share,
            ),
            if (url != null)
              _ShareAction(
                icon: PhosphorIcons.link(),
                label: l10n.shareCopyLink,
                onTap: () => _copyLink(url),
              ),
            _ShareAction(
              icon: PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
              label: l10n.shareMore,
              onTap: _busy ? null : _share,
            ),
          ],
        ),
      ],
    );
  }
}

/// The branded card itself (also what gets rendered to the image).
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.title,
    required this.meta,
    this.thumbnailPath,
  });

  final String title;
  final String meta;
  final String? thumbnailPath;

  static const _bars = [
    10, 18, 26, 14, 22, 30, 18, 12, 24, 28, 16, 10, 22, 26, //
    14, 20, 30, 24, 12, 18, 26, 22, 14, 10,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    final l10n = AppLocalizations.of(context);
    final thumb = thumbnailPath == null ? null : File(thumbnailPath!);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpace.s20),
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: thumb != null && thumb.existsSync()
                  ? Image.file(thumb, fit: BoxFit.cover, cacheWidth: 900)
                  : ColoredBox(
                      color: const Color(0x24FFFFFF),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
                          color: colors.heroText,
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.s14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.navTitle.copyWith(color: colors.heroText),
          ),
          Text(
            meta,
            style: text.caption.copyWith(color: const Color(0xD9FFFFFF)),
          ),
          const SizedBox(height: AppSpace.s14),
          ExcludeSemantics(
            child: SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in _bars)
                    Container(
                      width: 5,
                      height: h.toDouble(),
                      decoration: BoxDecoration(
                        color: const Color(0xB3FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s14),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.waveform(PhosphorIconsStyle.bold),
                color: colors.heroText,
                size: 16,
              ),
              const SizedBox(width: AppSpace.s6),
              Text(
                l10n.shareCardMadeWith,
                style: text.footnote.copyWith(
                  color: colors.heroText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(icon, color: colors.text, size: 24),
              ),
              const SizedBox(height: AppSpace.s6),
              Text(
                label,
                style: text.footnote.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
