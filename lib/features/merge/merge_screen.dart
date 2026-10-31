import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/merge.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/rules/merge_rules.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../picker/picker_screen.dart';

/// Merge (41, Pro): 2–10 files in list order with an optional crossfade.
class MergeScreen extends ConsumerStatefulWidget {
  const MergeScreen({super.key});

  @override
  ConsumerState<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends ConsumerState<MergeScreen> {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _state;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _state = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player.stop();
      }
      setState(
        () => _playing =
            state.playing && state.processingState != ProcessingState.completed,
      );
    });
  }

  @override
  void dispose() {
    _state?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// Preview plays the files back to back in order (no crossfade).
  Future<void> _togglePreview(List<SourceFile> files) async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_player.audioSource == null) {
      await _player.setAudioSources([
        for (final f in files) AudioSource.file(f.path),
      ]);
    }
    unawaited(_player.play());
  }

  Future<void> _resetPreview() async {
    await _player.stop();
    await _player.clearAudioSources();
  }

  Future<void> _add() async {
    await _resetPreview();
    if (!mounted) return;
    await context.push(
      '/pick',
      extra: const PickerIntent(purpose: PickerPurpose.mergeAdd),
    );
  }

  Future<void> _saveAs(MergeState merge) async {
    final choice = await AppBottomSheet.show<(OutFormat, Quality)>(
      context: context,
      builder: (_) => _SaveAsSheet(merge: merge),
    );
    if (choice != null) {
      ref.read(mergeProvider.notifier).setFormat(choice.$1, choice.$2);
    }
  }

  Future<void> _merge(MergeState merge) async {
    final l10n = AppLocalizations.of(context);
    final draft = merge.draft(l10n.mergeOutputName);
    if (draft == null) return;
    await _resetPreview();
    if (!mounted) return;
    ref.read(draftProvider.notifier).set(draft);
    context.push('/progress');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final merge = ref.watch(mergeProvider);
    final max = ref.watch(appConfigProvider).mergeMaxFiles;
    final files = merge.files;
    final canMerge = MergeRules.canMerge(files.length, maxFiles: max);
    final draft = merge.draft(l10n.mergeOutputName);
    final estimate = draft?.estimate().label ?? '–';
    final saveAs = merge.format.isLossless
        ? l10n.metaFormatSize(merge.format.label, estimate)
        : l10n.metaFormatBitrateSize(
            merge.format.label,
            merge.quality.kbps,
            estimate,
          );

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(
              title: l10n.mergeTitle,
              trailing: TextLinkButton(
                label: l10n.mergeAdd,
                onPressed: files.length < max ? _add : null,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.screen,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _MergeHero(
                        title: l10n.mergeSummary(
                          files.length,
                          Fmt.duration(merge.totalSeconds),
                        ),
                        playing: _playing,
                        onPlay: files.isEmpty
                            ? null
                            : () => _togglePreview(files),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpace.s12),
                  ),
                  if (files.length < MergeRules.minFiles)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        0,
                        AppSpace.screen,
                        AppSpace.s12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: StatusBox(
                          message: l10n.mergeEmpty,
                          tone: StatusTone.info,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.screen,
                    ),
                    sliver: SliverReorderableList(
                      itemCount: files.length,
                      onReorderItem: (from, to) {
                        unawaited(_resetPreview());
                        ref.read(mergeProvider.notifier).reorder(from, to);
                      },
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return Padding(
                          key: ValueKey(file.path),
                          padding: const EdgeInsets.only(bottom: AppSpace.s10),
                          child: _MergeRow(
                            index: index,
                            file: file,
                            onRemove: () {
                              unawaited(_resetPreview());
                              ref.read(mergeProvider.notifier).remove(index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s6,
                      AppSpace.screen,
                      AppSpace.s16,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          l10n.mergeCrossfade,
                          style: text.caption.copyWith(
                            color: colors.text2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpace.s8),
                        SegmentedControl<int>(
                          items: [
                            for (final s in MergeRules.crossfadeOptions)
                              SegmentedItem(
                                value: s,
                                label: s == 0
                                    ? l10n.crossfadeOff
                                    : l10n.crossfadeSeconds(s),
                              ),
                          ],
                          value: merge.crossfadeSec,
                          onChanged: ref
                              .read(mergeProvider.notifier)
                              .setCrossfade,
                        ),
                        const SizedBox(height: AppSpace.s16),
                        _SaveAsRow(value: saveAs, onTap: () => _saveAs(merge)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s8,
                AppSpace.screen,
                AppSpace.s8,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: l10n.mergeButton(files.length),
                    icon: PhosphorIcons.intersect(PhosphorIconsStyle.bold),
                    onPressed: canMerge ? () => _merge(merge) : null,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    l10n.mergeCaption(MergeRules.minFiles, max),
                    textAlign: TextAlign.center,
                    style: text.footnote.copyWith(color: colors.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeHero extends StatelessWidget {
  const _MergeHero({
    required this.title,
    required this.playing,
    required this.onPlay,
  });

  final String title;
  final bool playing;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s18),
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x29FFFFFF),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: PhosphorIcon(
              PhosphorIcons.intersect(PhosphorIconsStyle.bold),
              color: colors.heroText,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpace.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.navTitle.copyWith(color: colors.heroText),
                ),
                Text(
                  l10n.mergeOrderHint,
                  style: text.footnote.copyWith(
                    color: const Color(0xD9FFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Semantics(
            button: true,
            label: playing ? l10n.mergePause : l10n.mergePreview,
            excludeSemantics: true,
            child: Material(
              color: colors.heroText,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPlay,
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: PhosphorIcon(
                    playing
                        ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                        : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    color: colors.heroButtonText,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergeRow extends StatelessWidget {
  const _MergeRow({
    required this.index,
    required this.file,
    required this.onRemove,
  });

  final int index;
  final SourceFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final kind = file.isVideo
        ? l10n.statVideo
        : Fmt.extension(file.name).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s8,
        vertical: AppSpace.s10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: l10n.mergeReorder(file.name),
              child: SizedBox(
                width: 36,
                height: 44,
                child: PhosphorIcon(
                  PhosphorIcons.dotsSixVertical(PhosphorIconsStyle.bold),
                  color: colors.text3,
                  size: 20,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: text.footnote.copyWith(
                  color: colors.accentOnSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          MediaThumb(size: 48, path: file.thumbnailPath, isVideo: file.isVideo),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$kind · ${Fmt.duration(file.info.durationSec)}',
                  style: text.caption.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.mergeRemove(file.name),
            excludeSemantics: true,
            child: InkResponse(
              onTap: onRemove,
              radius: 22,
              child: SizedBox(
                width: 44,
                height: 44,
                child: PhosphorIcon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: colors.text2,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveAsRow extends StatelessWidget {
  const _SaveAsRow({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return Semantics(
      button: true,
      label: '${l10n.mergeSaveAs}, $value',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.fileAudio(),
                  color: colors.text2,
                  size: 22,
                ),
                const SizedBox(width: AppSpace.s14),
                Text(
                  l10n.mergeSaveAs,
                  style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: text.caption.copyWith(
                      color: colors.text2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s6),
                PhosphorIcon(
                  PhosphorIcons.caretRight(),
                  color: colors.text3,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Save as": the same format/quality presets as Convert (`05` §11).
class _SaveAsSheet extends StatefulWidget {
  const _SaveAsSheet({required this.merge});

  final MergeState merge;

  @override
  State<_SaveAsSheet> createState() => _SaveAsSheetState();
}

class _SaveAsSheetState extends State<_SaveAsSheet> {
  late OutFormat _format = widget.merge.format;
  late Quality _quality = widget.merge.quality;

  static const _rows = [
    [OutFormat.mp3, OutFormat.m4a, OutFormat.wav],
    [OutFormat.flac, OutFormat.aac, OutFormat.ogg],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final draft = widget.merge
        .copyWith(format: _format, quality: _quality)
        .draft(l10n.mergeOutputName);
    final qualities = [
      (Quality.standard, l10n.qualityStandard, l10n.qualityStandardDetail),
      (Quality.high, l10n.qualityHigh, l10n.qualityHighDetail),
      (Quality.best, l10n.qualityBest, l10n.qualityBestDetail),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mergeSaveAs,
          textAlign: TextAlign.center,
          style: text.dialogTitle,
        ),
        const SizedBox(height: AppSpace.s16),
        for (final row in _rows) ...[
          Row(
            children: [
              for (var i = 0; i < row.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: FormatChip(
                    label: row[i].label,
                    selected: row[i] == _format,
                    onTap: () => setState(() => _format = row[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s10),
        ],
        if (!_format.isLossless)
          for (final (quality, title, detail) in qualities) ...[
            RadioCard(
              title: title,
              subtitle: detail,
              sizeLabel: draft?.estimate(preset: quality.preset).label ?? '',
              selected: _quality == quality,
              onTap: () => setState(() => _quality = quality),
            ),
            const SizedBox(height: AppSpace.s8),
          ],
        const SizedBox(height: AppSpace.s8),
        PrimaryButton(
          label: l10n.done,
          onPressed: () => Navigator.of(context).pop((_format, _quality)),
        ),
      ],
    );
  }
}
