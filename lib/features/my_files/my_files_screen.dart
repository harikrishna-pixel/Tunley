import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/personalization.dart';
import '../../core/rules/ringtone_rules.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../common/share_tracking.dart';
import '../../l10n/app_localizations.dart';
import '../more_apps/more_apps_screen.dart';
import '../picker/picker_screen.dart';

enum _Filter { all, audio, ringtones, alarms }

class MyFilesScreen extends ConsumerStatefulWidget {
  const MyFilesScreen({super.key});

  @override
  ConsumerState<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends ConsumerState<MyFilesScreen> {
  /// Created on the first play; disposing an idle player races its setup.
  AudioPlayer? _player;
  final _search = TextEditingController();
  StreamSubscription<PlayerState>? _state;
  _Filter _filter = _Filter.all;
  bool _searching = false;
  String? _playing;

  AudioPlayer get _audio {
    final existing = _player;
    if (existing != null) return existing;
    final player = _player = AudioPlayer();
    _state = player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        player.stop();
        setState(() => _playing = null);
      }
    });
    return player;
  }

  @override
  void dispose() {
    _state?.cancel();
    _player?.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(LibraryItem item) async {
    if (_playing == item.id) {
      await _audio.stop();
      setState(() => _playing = null);
      return;
    }
    final path = ref.read(libraryRepositoryProvider).absolutePath(item);
    setState(() => _playing = item.id);
    try {
      await _audio.setFilePath(path);
      ref.read(analyticsProvider).filePlayed(screen: 'my_files');
      unawaited(_audio.play());
    } catch (_) {
      if (mounted) setState(() => _playing = null);
    }
  }

  bool _matches(LibraryItem item) {
    final keep = switch (_filter) {
      _Filter.all => true,
      _Filter.audio => !item.isTone,
      _Filter.ringtones =>
        item.toneType == ToneType.ringtone ||
            item.toneType == ToneType.textTone,
      _Filter.alarms => item.toneType == ToneType.alarm,
    };
    final query = _search.text.trim().toLowerCase();
    return keep && (query.isEmpty || item.name.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final all = ref.watch(libraryItemsProvider).value;
    final filtered = all?.where(_matches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s12,
            AppSpace.screen,
            AppSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.tabFiles, style: text.largeTitle),
                ),
              ),
              if (all != null && all.isNotEmpty)
                Semantics(
                  button: true,
                  label: l10n.search,
                  excludeSemantics: true,
                  child: Material(
                    color: colors.surface,
                    shape: CircleBorder(side: BorderSide(color: colors.border)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) _search.clear();
                      }),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          _searching
                              ? PhosphorIcons.x(PhosphorIconsStyle.bold)
                              : PhosphorIcons.magnifyingGlass(),
                          size: 20,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: all == null
              ? const SizedBox.shrink()
              : AnimatedSwitcher(
                  duration: AppMotion.of(
                    AppMotion.tab,
                    MediaQuery.disableAnimationsOf(context),
                  ),
                  child: all.isEmpty
                      ? const _EmptyFiles(key: ValueKey('empty'))
                      : ListView(
                          key: const ValueKey('list'),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen,
                            0,
                            AppSpace.screen,
                            AppSpace.s24,
                          ),
                          children: [
                            if (_searching) ...[
                              TextField(
                                controller: _search,
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                style: text.body,
                                decoration: InputDecoration(
                                  hintText: l10n.searchFiles,
                                  hintStyle: text.body.copyWith(
                                    color: colors.text3,
                                  ),
                                  prefixIcon: Icon(
                                    PhosphorIcons.magnifyingGlass(),
                                    color: colors.text3,
                                  ),
                                  filled: true,
                                  fillColor: colors.surface2,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: AppSpace.s12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.status,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.s12),
                            ],
                            _Filters(
                              value: _filter,
                              onChanged: (f) => setState(() => _filter = f),
                            ),
                            const SizedBox(height: AppSpace.s14),
                            if (filtered!.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(AppSpace.s24),
                                child: Text(
                                  l10n.filesNoMatch,
                                  textAlign: TextAlign.center,
                                  style: text.body.copyWith(
                                    color: colors.text2,
                                  ),
                                ),
                              )
                            else
                              ListGroup(
                                children: [
                                  for (final item in filtered)
                                    _FileRow(
                                      item: item,
                                      playing: _playing == item.id,
                                      onPlay: () => _togglePlay(item),
                                    ),
                                ],
                              ),
                            const SizedBox(height: AppSpace.s14),
                            Text(
                              l10n.filesFooter,
                              textAlign: TextAlign.center,
                              style: text.footnote.copyWith(
                                color: colors.text2,
                              ),
                            ),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labels = {
      _Filter.all: l10n.filterAll,
      _Filter.audio: l10n.filterAudio,
      _Filter.ringtones: l10n.filterRingtones,
      _Filter.alarms: l10n.filterAlarms,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            if (entry.key != _Filter.all) const SizedBox(width: AppSpace.s8),
            Semantics(
              button: true,
              selected: entry.key == value,
              child: Material(
                color: entry.key == value ? colors.accent : colors.surface,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: entry.key == value ? colors.accent : colors.border,
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onChanged(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s16,
                      vertical: AppSpace.s10,
                    ),
                    child: Text(
                      entry.value,
                      style: context.appText.caption.copyWith(
                        color: entry.key == value
                            ? colors.accentText
                            : colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String relativeDate(AppLocalizations l10n, DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  if (current.difference(date).inMinutes < 60 && day == today) {
    return l10n.justNow;
  }
  if (today.difference(day).inDays == 1) return l10n.yesterday;
  return DateFormat.MMMd(l10n.localeName).format(date);
}

class _FileRow extends ConsumerWidget {
  const _FileRow({
    required this.item,
    required this.playing,
    required this.onPlay,
  });

  final LibraryItem item;
  final bool playing;
  final VoidCallback onPlay;

  Future<void> _more(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(libraryRepositoryProvider);
    final action = await AppBottomSheet.show<String>(
      context: context,
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        Widget row(
          String id,
          IconData icon,
          String label, {
          bool danger = false,
        }) {
          final color = danger ? colors.danger : colors.text;
          return InkWell(
            onTap: () => Navigator.of(sheetContext).pop(id),
            borderRadius: BorderRadius.circular(AppRadius.row),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: AppSpace.s14),
                  Text(
                    label,
                    style: sheetContext.appText.subhead.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sheetContext.appText.dialogTitle,
            ),
            const SizedBox(height: AppSpace.s8),
            row('share', PhosphorIcons.export(), l10n.share),
            row('rename', PhosphorIcons.pencilSimple(), l10n.rename),
            row(
              'ringtone',
              PhosphorIcons.bellRinging(),
              l10n.setRingtoneAction,
            ),
            row('delete', PhosphorIcons.trash(), l10n.delete, danger: true),
          ],
        );
      },
    );
    if (!context.mounted) return;
    switch (action) {
      case 'share':
        await shareAndTrack(
          ref,
          ShareParams(files: [XFile(repo.absolutePath(item))]),
          format: item.format,
          screen: 'my_files',
        );
      case 'rename':
        await _rename(context, repo);
      case 'ringtone':
        await _setAsRingtone(context, ref);
      case 'delete':
        final confirmed = await AppAlert.show<bool>(
          context: context,
          title: l10n.deleteTitle(item.name),
          body: l10n.deleteBody,
          actions: [
            AlertAction(l10n.deleteConfirm, true, tone: AlertTone.destructive),
            AlertAction(l10n.keep, false),
          ],
        );
        if (confirmed == true) {
          await repo.delete(item);
          ref.read(analyticsProvider).fileDeleted(format: item.format);
        }
    }
  }

  Future<void> _setAsRingtone(BuildContext context, WidgetRef ref) async {
    if (item.isTone) {
      final os = await ref.read(audioEngineProvider).appInfo();
      ref
          .read(analyticsProvider)
          .guideOpened(entry: 'my_files', iosVersion: os.osVersion);
      if (context.mounted) context.push('/guide', extra: item);
      return;
    }
    final path = ref.read(libraryRepositoryProvider).absolutePath(item);
    final info = await ref.read(audioEngineProvider).inspect(path);
    if (!context.mounted) return;
    ref
        .read(draftProvider.notifier)
        .start(
          SourceFile(path: path, name: item.name, info: info),
          mode: ConvertMode.ringtone,
        );
    context.push('/convert');
  }

  Future<void> _rename(BuildContext context, LibraryRepository repo) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: Fmt.baseName(item.name));
    String? error;
    await AppDialog.show<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final colors = dialogContext.colors;
          final text = dialogContext.appText;
          Future<void> submit() async {
            final analytics = ProviderScope.containerOf(
              context,
              listen: false,
            ).read(analyticsProvider);
            final ok = await repo.rename(item, controller.text);
            if (ok) analytics.fileRenamed(format: item.format);
            if (!dialogContext.mounted) return;
            if (ok) {
              Navigator.of(dialogContext).pop();
            } else {
              setState(() => error = l10n.renameTaken);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.renameTitle, style: text.dialogTitle),
              const SizedBox(height: AppSpace.s14),
              TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (_) => submit(),
                style: text.body,
                decoration: InputDecoration(
                  labelText: l10n.renameHint,
                  errorText: error,
                  suffixText: '.${item.name.split('.').last}',
                  filled: true,
                  fillColor: colors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s20),
              PrimaryButton(label: l10n.save, onPressed: submit),
              const SizedBox(height: AppSpace.s4),
              Center(
                child: TextLinkButton(
                  label: l10n.cancel,
                  muted: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final duration = Fmt.duration(item.durationSec);
    final base = switch (item.toneType) {
      ToneType.ringtone => l10n.metaRingtone(duration),
      ToneType.alarm => l10n.metaAlarm(duration),
      ToneType.textTone => l10n.metaTextTone(duration),
      null => l10n.metaFormatSize(
        item.format.toUpperCase(),
        Fmt.bytes(item.bytes),
      ),
    };
    final meta = l10n.metaWithDate(base, relativeDate(l10n, item.createdAt));

    return InkWell(
      onTap: () => context.push('/item', extra: item),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpace.s14,
          top: AppSpace.s10,
          bottom: AppSpace.s10,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'item:${item.id}',
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.isTone ? null : colors.accentSoft,
                  gradient: item.isTone ? colors.heroGradient : null,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: PhosphorIcon(
                  item.isTone
                      ? PhosphorIcons.bellRinging()
                      : PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
                  color: item.isTone ? colors.heroText : colors.accentOnSoft,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    meta,
                    style: text.footnote.copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: playing ? l10n.pause : l10n.play,
              excludeSemantics: true,
              child: Material(
                color: colors.accentSoft,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: PhosphorIcon(
                      playing
                          ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                          : PhosphorIcons.play(PhosphorIconsStyle.fill),
                      size: 16,
                      color: colors.accentOnSoft,
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.moreActions(item.name),
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => _more(context, ref),
                radius: 24,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
                    color: colors.text2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFiles extends ConsumerStatefulWidget {
  const _EmptyFiles({super.key});

  @override
  ConsumerState<_EmptyFiles> createState() => _EmptyFilesState();
}

class _EmptyFilesState extends ConsumerState<_EmptyFiles> {
  @override
  void initState() {
    super.initState();
    final hasShrink = ref
        .read(appConfigProvider)
        .moreApps
        .any((app) => app.id == 'shrink');
    if (hasShrink) {
      ref
          .read(analyticsProvider)
          .houseCardShown(app: 'shrink', screen: 'my_files');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final shrink = ref
        .watch(appConfigProvider)
        .moreApps
        .where((app) => app.id == 'shrink')
        .firstOrNull;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
                      color: colors.accentOnSoft,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s20),
                  Text(l10n.filesEmptyTitle, style: text.title),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    l10n.filesEmptyBody,
                    textAlign: TextAlign.center,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                  const SizedBox(height: AppSpace.s20),
                  SizedBox(
                    width: 240,
                    child: PrimaryButton(
                      label: l10n.makeFirstSound,
                      icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      onPressed: () =>
                          context.push('/pick', extra: const PickerIntent()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (shrink != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.s16,
            ),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.s14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.squaresFour(),
                      color: colors.text2,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shrink.name,
                          style: text.subhead.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          shrink.pitch == null
                              ? l10n.moreFromMarberxShort
                              : l10n.moreFromMarberx(shrink.pitch!),
                          style: text.footnote.copyWith(color: colors.text2),
                        ),
                      ],
                    ),
                  ),
                  if (shrink.hasStoreId)
                    TextLinkButton(
                      label: l10n.get,
                      onPressed: () {
                        ref
                            .read(analyticsProvider)
                            .houseCardTapped(
                              app: shrink.id,
                              screen: 'my_files',
                            );
                        openMarberxApp(ref, shrink, screen: 'my_files');
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
