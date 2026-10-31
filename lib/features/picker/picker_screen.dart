import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/batch.dart';
import '../../app/config.dart';
import '../../app/merge.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../errors/error_screen.dart';
import '../prompts/notification_prompt.dart';

enum PickerTab { videos, audio, recent }

/// [convert]: one file → Convert, several (Pro) → Batch. [merge]: from the
/// Home tile, on to Merge. [mergeAdd]: Merge's "Add", pops back.
enum PickerPurpose { convert, merge, mergeAdd }

/// How the picker was opened (hero, tool tile, Result cross-sell, Merge).
class PickerIntent {
  const PickerIntent({
    this.tab,
    this.mode,
    this.openTrim = false,
    this.purpose = PickerPurpose.convert,
  });

  final PickerTab? tab;
  final ConvertMode? mode;

  /// Trim & fade / Volume boost tiles go straight on to the trim editor.
  final bool openTrim;
  final PickerPurpose purpose;

  bool get isMerge => purpose != PickerPurpose.convert;
}

const _audioExtensions = [
  'mp3', 'm4a', 'wav', 'aiff', 'aif', 'caf', 'flac', 'aac', 'm4r', //
  'mp4', 'mov', 'm4v',
];

class PickerScreen extends ConsumerStatefulWidget {
  const PickerScreen({super.key, this.intent = const PickerIntent()});

  final PickerIntent intent;

  @override
  ConsumerState<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends ConsumerState<PickerScreen> {
  late PickerTab _tab;

  /// Selected paths in tap order.
  List<String> _selection = const [];
  bool _loading = false;

  /// Where each file came from, for `file_picked.source`.
  final Map<String, String> _origin = {};

  /// Pro picks several files (batch); merge always does.
  bool get _multi => widget.intent.isMerge || ref.read(isProProvider);

  int get _limit {
    final config = ref.read(appConfigProvider);
    return switch (widget.intent.purpose) {
      PickerPurpose.convert => _multi ? config.batchMaxFiles : 1,
      PickerPurpose.merge => config.mergeMaxFiles,
      PickerPurpose.mergeAdd => ref.read(mergeProvider.notifier).room,
    };
  }

  void _select(SourceFile source) {
    setState(() {
      if (!_multi) {
        _selection = [source.path];
      } else if (_selection.contains(source.path)) {
        _selection = [..._selection]..remove(source.path);
      } else if (_selection.length < _limit) {
        _selection = [..._selection, source.path];
      } else {
        TunelyToast.show(
          context,
          message: AppLocalizations.of(context).pickerLimitReached(_limit),
          tone: ToastTone.info,
        );
      }
    });
  }

  void _selectAll(List<SourceFile> sources) {
    for (final source in sources) {
      if (!_selection.contains(source.path)) _select(source);
    }
  }

  @override
  void initState() {
    super.initState();
    final personal = ref.read(personalizationProvider);
    _tab =
        widget.intent.tab ??
        (personal.picker == PickerSource.audioFiles
            ? PickerTab.audio
            : PickerTab.videos);
    if (widget.intent.isMerge) return;
    final first = ref
        .read(pickedSourcesProvider)
        .where((s) => s.isVideo == (_tab == PickerTab.videos))
        .firstOrNull;
    if (first != null) _selection = [first.path];
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);

  Future<SourceFile?> _inspect(
    String path, {
    String? name,
    required String origin,
  }) async {
    _origin[path] = origin;
    final info = await _engine.inspect(path);
    final thumb = info.hasVideo ? await _engine.thumbnail(path) : null;
    final source = SourceFile(
      path: path,
      name: name ?? path.split('/').last,
      info: info,
      thumbnailPath: thumb,
    );
    ref.read(pickedSourcesProvider.notifier).add(source);
    return source;
  }

  Future<void> _run(
    Future<void> Function() body, {
    bool retried = false,
  }) async {
    setState(() => _loading = true);
    ErrorChoice? choice;
    try {
      await body();
    } on EngineException catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        choice = await context.push<ErrorChoice>(
          '/error',
          extra: ErrorArgs(error.code),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted && choice == ErrorChoice.retry && !retried) {
      await _run(body, retried: true);
    }
  }

  int get _room => _multi ? (_limit - _selection.length).clamp(1, _limit) : 1;

  Future<void> _pickVideos() => _run(() async {
    final paths = await _engine.pickVideos(maxCount: _room);
    final sources = <SourceFile>[];
    for (final path in paths) {
      final source = await _inspect(path, origin: 'photos');
      if (source != null) sources.add(source);
    }
    if (mounted) _selectAll(sources);
  });

  Future<void> _pickAudio() => _run(() async {
    final files = _multi
        ? await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: _audioExtensions,
          )
        : [
            ?await FilePicker.pickFile(
              type: FileType.custom,
              allowedExtensions: _audioExtensions,
            ),
          ];
    final sources = <SourceFile>[];
    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      final source = await _inspect(path, name: file.name, origin: 'files');
      if (source != null) sources.add(source);
      if (sources.length >= _room) break;
    }
    if (!mounted || sources.isEmpty) return;
    if (!_multi) {
      setState(
        () => _tab = sources.first.isVideo ? PickerTab.videos : PickerTab.audio,
      );
    }
    _selectAll(sources);
  });

  Future<void> _pickRecent(LibraryItem item) => _run(() async {
    final repo = ref.read(libraryRepositoryProvider);
    final path = repo.absolutePath(item);
    if (_selection.contains(path)) {
      final source = ref
          .read(pickedSourcesProvider)
          .where((s) => s.path == path)
          .firstOrNull;
      if (source != null && mounted) _select(source);
      return;
    }
    final source = await _inspect(path, name: item.name, origin: 'recent');
    if (mounted && source != null) _select(source);
  });

  Future<void> _continueWith(List<SourceFile> sources) async {
    if (sources.isEmpty) return;
    final first = sources.first;
    ref
        .read(analyticsProvider)
        .filePicked(
          source: _origin[first.path] ?? 'photos',
          type: first.isVideo ? 'video' : 'audio',
          count: sources.length,
          durationS: first.info.durationSec,
          sizeMb: mb(sources.fold<int>(0, (sum, s) => sum + s.info.bytes)),
        );
    switch (widget.intent.purpose) {
      case PickerPurpose.mergeAdd:
        ref.read(mergeProvider.notifier).add(sources);
        context.pop();
      case PickerPurpose.merge:
        ref.read(mergeProvider.notifier)
          ..reset()
          ..add(sources);
        context.pushReplacement('/merge');
      case PickerPurpose.convert:
        if (sources.length == 1) return _continue(sources.single);
        await _startBatch(sources);
    }
  }

  Future<void> _startBatch(List<SourceFile> sources) async {
    final l10n = AppLocalizations.of(context);
    await askNotifications(context, ref, NotifyReason.batch);
    if (!mounted) return;
    unawaited(
      ref
          .read(batchProvider.notifier)
          .start(
            sources,
            BatchCopy(
              backgroundTitle: l10n.batchSystemTitle(sources.length),
              progress: (done, total) => l10n.batchSystemProgress(done, total),
              doneTitle: l10n.batchNotificationTitle,
              doneBody: l10n.batchNotificationBody,
            ),
          ),
    );
    context.pushReplacement('/batch');
  }

  Future<void> _continue(SourceFile source) async {
    final info = source.info;
    if (!info.hasAudio || info.isProtected) {
      await context.push<ErrorChoice>(
        '/error',
        extra: ErrorArgs(
          info.isProtected
              ? EngineErrorCode.protected
              : EngineErrorCode.noAudio,
          sourceName: source.name,
          sourceBytes: info.bytes,
          isVideo: source.isVideo,
        ),
      );
      return;
    }
    if (!mounted) return;
    ref.read(draftProvider.notifier).start(source, mode: widget.intent.mode);
    context.push('/convert', extra: widget.intent.openTrim);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final picked = ref.watch(pickedSourcesProvider);
    final videos = picked.where((s) => s.isVideo).toList();
    final audio = picked.where((s) => !s.isVideo).toList();
    final byPath = {for (final s in picked) s.path: s};
    final selection = [
      for (final path in _selection)
        if (byPath[path] != null) byPath[path]!,
    ];
    final chosen = _selection.toSet();
    final isPro = ref.watch(isProProvider);
    final hint = widget.intent.isMerge
        ? l10n.pickerMergeHint(_limit)
        : isPro
        ? l10n.pickerBatchProHint(_limit)
        : l10n.pickerBatchHint;

    final body = switch (_tab) {
      PickerTab.videos => _VideoGrid(
        videos: videos,
        selected: chosen,
        onPick: _loading ? null : _pickVideos,
        onSelect: _select,
      ),
      PickerTab.audio => _AudioList(
        files: audio,
        selected: chosen,
        onBrowse: _loading ? null : _pickAudio,
        onSelect: _select,
      ),
      PickerTab.recent => _RecentList(
        onSelect: _loading ? null : _pickRecent,
        selected: chosen,
      ),
    };

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NavHeader(
              title: l10n.pickerTitle,
              trailing: Semantics(
                button: true,
                label: l10n.pickerOpenFiles,
                child: InkResponse(
                  onTap: _loading ? null : _pickAudio,
                  radius: 24,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: PhosphorIcon(
                      PhosphorIcons.folder(),
                      color: colors.link,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                0,
                AppSpace.screen,
                AppSpace.s12,
              ),
              child: SegmentedControl<PickerTab>(
                items: [
                  SegmentedItem(
                    value: PickerTab.videos,
                    label: l10n.pickerVideos,
                  ),
                  SegmentedItem(
                    value: PickerTab.audio,
                    label: l10n.pickerAudio,
                  ),
                  SegmentedItem(
                    value: PickerTab.recent,
                    label: l10n.pickerRecent,
                  ),
                ],
                value: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.of(
                  AppMotion.tab,
                  MediaQuery.disableAnimationsOf(context),
                ),
                child: KeyedSubtree(key: ValueKey(_tab), child: body),
              ),
            ),
            _Footer(
              selection: selection,
              loading: _loading,
              hint: hint,
              onContinue: selection.isEmpty
                  ? null
                  : () => _continueWith(selection),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({
    required this.videos,
    required this.selected,
    required this.onPick,
    required this.onSelect,
  });

  final List<SourceFile> videos;
  final Set<String> selected;
  final VoidCallback? onPick;
  final ValueChanged<SourceFile> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: Text(
                l10n.pickerVideosHint,
                style: text.caption.copyWith(color: colors.text2),
              ),
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          delegate: SliverChildBuilderDelegate(childCount: videos.length + 1, (
            context,
            index,
          ) {
            if (index == 0) {
              return Semantics(
                button: true,
                label: l10n.pickerChooseVideos,
                excludeSemantics: true,
                child: Material(
                  color: colors.accentSoft,
                  child: InkWell(
                    onTap: onPick,
                    // A square tile: at large text sizes the label scales to
                    // fit (VoiceOver still reads the full label).
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                            color: colors.accentOnSoft,
                            size: 30,
                          ),
                          const SizedBox(height: AppSpace.s6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s8,
                            ),
                            child: Text(
                              l10n.pickerChooseVideos,
                              textAlign: TextAlign.center,
                              style: text.footnote.copyWith(
                                color: colors.accentOnSoft,
                                fontWeight: FontWeight.w700,
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
            final video = videos[index - 1];
            return _VideoTile(
              video: video,
              selected: selected.contains(video.path),
              onTap: () => onSelect(video),
            );
          }),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.selected,
    required this.onTap,
  });

  final SourceFile video;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${video.name}, ${Fmt.duration(video.info.durationSec)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                MediaThumb(
                  size: constraints.maxWidth,
                  path: video.thumbnailPath,
                  radius: 0,
                  heroTag: 'thumb:${video.path}',
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x8C000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: PhosphorIcon(
                    PhosphorIcons.videoCamera(),
                    color: colors.heroText,
                    size: 16,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: Text(
                    Fmt.duration(video.info.durationSec),
                    style: context.appText.footnote.copyWith(
                      color: colors.heroText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.accent, width: 3),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color: colors.accentText,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AudioList extends StatelessWidget {
  const _AudioList({
    required this.files,
    required this.selected,
    required this.onBrowse,
    required this.onSelect,
  });

  final List<SourceFile> files;
  final Set<String> selected;
  final VoidCallback? onBrowse;
  final ValueChanged<SourceFile> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.s24,
      ),
      children: [
        _FileRow(
          icon: PhosphorIcons.folderOpen(),
          title: l10n.pickerBrowseFiles,
          subtitle: l10n.pickerBrowseFilesHint,
          selected: null,
          onTap: onBrowse,
        ),
        for (final file in files) ...[
          const SizedBox(height: AppSpace.s8),
          _FileRow(
            icon: PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
            title: file.name,
            subtitle: l10n.sourceAudioMeta(
              Fmt.extension(file.name),
              Fmt.duration(file.info.durationSec),
              Fmt.bytes(file.info.bytes),
            ),
            selected: selected.contains(file.path),
            onTap: () => onSelect(file),
          ),
        ],
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Null hides the radio (action rows).
  final bool? selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    final isSelected = selected ?? false;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Icon(icon, color: colors.accentOnSoft, size: 22),
                ),
                const SizedBox(width: AppSpace.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: text.caption.copyWith(color: colors.text2),
                      ),
                    ],
                  ),
                ),
                if (selected != null) _Radio(selected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accent : null,
        border: Border.all(
          color: selected ? colors.accent : colors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colors.accentText,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({required this.onSelect, required this.selected});

  final ValueChanged<LibraryItem>? onSelect;
  final Set<String> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(libraryItemsProvider).value ?? const [];
    final repo = ref.watch(libraryRepositoryProvider);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Text(
          l10n.pickerRecentEmpty,
          textAlign: TextAlign.center,
          style: context.appText.body.copyWith(color: context.colors.text2),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.s24,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FileRow(
          icon: item.isTone
              ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill)
              : PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
          title: item.name,
          subtitle: l10n.sourceAudioMeta(
            item.format.toUpperCase(),
            Fmt.duration(item.durationSec),
            Fmt.bytes(item.bytes),
          ),
          selected: selected.contains(repo.absolutePath(item)),
          onTap: onSelect == null ? null : () => onSelect!(item),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.selection,
    required this.loading,
    required this.hint,
    required this.onContinue,
  });

  final List<SourceFile> selection;
  final bool loading;
  final String hint;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final source = selection.length == 1 ? selection.single : null;
    final title = loading
        ? l10n.pickerLoading
        : selection.length > 1
        ? l10n.pickerSelectedCount(selection.length)
        : source == null
        ? l10n.pickerNothingSelected
        : source.isVideo
        ? l10n.pickerVideoSelected(Fmt.duration(source.info.durationSec))
        : l10n.pickerAudioSelected;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tab,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpace.s12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s14,
            AppSpace.screen,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      hint,
                      style: text.footnote.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              SizedBox(
                width: 168,
                child: PrimaryButton(
                  label: l10n.continueAction,
                  icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  iconTrailing: true,
                  onPressed: loading ? null : onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
