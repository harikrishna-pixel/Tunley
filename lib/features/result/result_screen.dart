import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/ads.dart';
import '../../app/config.dart';
import '../../core/ads/ads_service.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/library/usage_store.dart';
import '../../core/rules/house_card_policy.dart';
import '../../app/state.dart';
import '../../app/transitions.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/personalization.dart';
import '../common/share_tracking.dart';
import '../paywall/paywall_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../errors/save_failed_sheet.dart';
import '../../app/monetization.dart';
import '../../core/rules/paywall_triggers.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/upsell.dart';
import '../ads/ad_break.dart';
import '../more_apps/house_card.dart';
import '../more_apps/more_apps_screen.dart';
import '../prompts/milestone_dialog.dart';
import '../prompts/rating_dialog.dart';
import '../prompts/share_card_sheet.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.item});

  final LibraryItem item;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _position;
  StreamSubscription<PlayerState>? _state;
  List<double> _peaks = const [];
  double _played = 0;
  bool _playing = false;
  bool _started = false;
  bool _saving = false;
  int? _upsellCount;
  MoreApp? _houseApp;

  /// P4/P5 showed, or a save failed, in this Result flow: no ad break.
  bool _paywallInFlow = false;
  bool _errorInFlow = false;

  bool get _fresh => ref.read(jobProvider)?.item?.id == item.id;

  LibraryItem get item => widget.item;
  String get _path => ref.read(libraryRepositoryProvider).absolutePath(item);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    afterRouteTransition(context, _prepare);
  }

  Future<void> _prepare() async {
    unawaited(_prompts());
    try {
      final peaks = await ref
          .read(audioEngineProvider)
          .waveform(_path, buckets: 48);
      if (mounted) setState(() => _peaks = peaks);
    } on EngineException {
      // Preview only.
    }
    _position = _player.positionStream.listen((position) {
      final total = item.durationSec <= 0 ? 1 : item.durationSec;
      if (mounted) {
        setState(
          () => _played = (position.inMilliseconds / 1000 / total).clamp(0, 1),
        );
      }
    });
    _state = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      setState(
        () => _playing =
            state.playing && state.processingState != ProcessingState.completed,
      );
    });
  }

  @override
  void dispose() {
    _position?.cancel();
    _state?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// At most one prompt, only for a result just made (never a library item):
  /// milestone (30), then P5 / P4, then rating (26).
  Future<void> _prompts() async {
    if (!_fresh) return;
    unawaited(ref.read(adsProvider.notifier).preload(AdFormat.interstitial));
    if (await maybeShowMilestone(context, ref, item) || !mounted) return;
    if (await _offerPro() || !mounted) {
      _paywallInFlow = true;
      return;
    }
    await _offerHouseCard();
    if (!mounted) return;
    await maybeAskForRating(context, ref, ringtone: item.isTone);
  }

  /// 09d: never with the P4 card or in a session with an ad break.
  Future<void> _offerHouseCard() async {
    final config = ref.read(appConfigProvider);
    final usage = ref.read(usageStoreProvider);
    final now = DateTime.now();
    final memory = await usage.houseCard();
    final allowed = HouseCardPolicy.canShow(
      HouseCardRequest(
        memory: memory,
        now: now,
        installedAt: await usage.installedAt(),
        isPro: ref.read(isProProvider),
        success: true,
        lifetimeSuccesses: await usage.lifetimeConversions(),
        adBreakThisSession: ref.read(adsProvider).adBreakThisSession,
        upsellCardShowing: _upsellCount != null,
        everyNthSuccess: config.houseCard.everyNthSuccess,
        minDaysSinceInstall: config.houseCard.minDaysSinceInstall,
      ),
    );
    if (!allowed || !mounted) return;
    final id = HouseCardPolicy.pick([
      for (final a in config.moreApps) a.id,
    ], fromVideo: item.sourceIsVideo);
    final app = config.moreApps.where((a) => a.id == id).firstOrNull;
    if (app == null) return;
    await usage.writeHouseCard(HouseCardPolicy.shown(memory, now));
    ref.read(analyticsProvider).houseCardShown(app: app.id, screen: 'result');
    if (mounted) setState(() => _houseApp = app);
  }

  Future<void> _hideHouseCard(MoreApp app) async {
    final usage = ref.read(usageStoreProvider);
    await usage.writeHouseCard(
      HouseCardPolicy.hidden(
        await usage.houseCard(),
        DateTime.now(),
        hideDays: ref.read(appConfigProvider).houseCard.hideDays,
      ),
    );
    ref.read(analyticsProvider).houseCardHidden(app: app.id, screen: 'result');
    if (mounted) setState(() => _houseApp = null);
  }

  Future<void> _adBreak(AdBreakTrigger trigger) async {
    if (!_fresh) return;
    await maybeAdBreak(
      context,
      ref,
      trigger: trigger,
      formatLabel: item.format.toUpperCase(),
      ringtone: item.isTone,
      afterErrorInFlow: _errorInFlow,
      paywallInFlow: _paywallInFlow,
      houseCardOnScreen: _houseApp != null,
    );
  }

  Future<void> _done() async {
    await _adBreak(AdBreakTrigger.done);
    if (mounted) context.go('/home');
  }

  /// P5 after the 10th file, otherwise P4 after the 3rd success today.
  Future<bool> _offerPro() async {
    if (ref.read(isProProvider)) return false;
    final paywall = ref.read(paywallProvider.notifier);
    final lifetime = await ref.read(usageStoreProvider).lifetimeConversions();
    if (!mounted) return false;
    if (paywall.canShow(PaywallTrigger.p5, lifetimeFiles: lifetime)) {
      final delay = ref.read(appConfigProvider).rating.delayMs;
      await Future<void>.delayed(Duration(milliseconds: delay));
      if (!mounted ||
          !paywall.canShow(PaywallTrigger.p5, lifetimeFiles: lifetime)) {
        return false;
      }
      await paywall.markShown(PaywallTrigger.p5);
      if (mounted) await showHeavyUser(context, ref);
      return true;
    }
    if (paywall.canShow(PaywallTrigger.p4)) {
      await paywall.markShown(PaywallTrigger.p4);
      if (mounted) {
        setState(() => _upsellCount = ref.read(freeLimitProvider).usedToday);
        unawaited(PaywallView.open(context, trigger: 'upsell_card'));
      }
      return true;
    }
    return false;
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_player.audioSource == null) {
      await _player.setFilePath(_path);
    }
    ref.read(analyticsProvider).filePlayed(screen: 'result');
    unawaited(_player.play());
  }

  Future<void> _share() async {
    if (item.isTone) return showShareCard(context, ref, item, entry: 'result');
    await shareAndTrack(
      ref,
      ShareParams(files: [XFile(_path)]),
      format: item.format,
      screen: 'result',
    );
  }

  Future<void> _setAsRingtone() async {
    await _adBreak(AdBreakTrigger.ringtone);
    final os = await ref.read(audioEngineProvider).appInfo();
    ref
        .read(analyticsProvider)
        .guideOpened(entry: 'result', iosVersion: os.osVersion);
    if (mounted) context.push('/guide', extra: item);
  }

  Future<void> _saveToFiles({bool chooseAgain = false}) async {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(audioEngineProvider);
    final usage = ref.read(usageStoreProvider);
    setState(() => _saving = true);
    try {
      var folder = chooseAgain ? null : await usage.folderBookmark();
      if (folder == null) {
        folder = await engine.pickFolder();
        if (folder == null) return;
        await usage.setFolderBookmark(folder);
        ref
            .read(analyticsProvider)
            .saveFolderChosen(
              isIcloud: await engine.bookmarkedFolderIsICloud(folder),
            );
      }
      await engine.copyToBookmarkedFolder(_path, folder);
      ref
          .read(analyticsProvider)
          .fileSaved(destination: 'tunely_folder', format: item.format);
      final name = await engine.bookmarkedFolderName(folder) ?? l10n.homeTitle;
      if (!mounted) return;
      TunelyToast.show(context, message: l10n.savedToFolder(name));
      setState(() => _saving = false);
      await _adBreak(AdBreakTrigger.save);
    } on EngineException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _saveFailed(error.code);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveFailed(EngineErrorCode code) async {
    final l10n = AppLocalizations.of(context);
    _errorInFlow = true;
    final folderGone = code == EngineErrorCode.staleBookmark;
    final choice = await SaveFailedSheet.show(
      context,
      format: item.isTone ? l10n.toneRingtone : item.format.toUpperCase(),
      folderGone: folderGone,
      destinationFull: code == EngineErrorCode.noSpace,
    );
    if (!mounted) return;
    switch (choice) {
      case SaveChoice.saveOnIphone:
        TunelyToast.show(context, message: l10n.savedOnIphone);
      case SaveChoice.retry:
        await _saveToFiles();
      case SaveChoice.chooseFolder:
        await _saveToFiles(chooseAgain: true);
      case SaveChoice.share:
        await _share();
      case null:
        break;
    }
  }

  Future<void> _crossSell() async {
    final draft = ref.read(draftProvider);
    final engine = ref.read(audioEngineProvider);
    SourceFile? source = draft == null || draft.isMerge ? null : draft.source;
    if (source == null || !File(source.path).existsSync()) {
      final info = await engine.inspect(_path);
      source = SourceFile(path: _path, name: item.name, info: info);
    }
    if (!mounted) return;
    final notifier = ref.read(draftProvider.notifier);
    if (item.isTone) {
      notifier.start(source, mode: ConvertMode.audioFile);
    } else {
      notifier.start(source, mode: ConvertMode.ringtone);
    }
    context.push('/convert');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final config = ref.watch(appConfigProvider);
    final isPro = ref.watch(isProProvider);
    ref.watch(freeLimitProvider);
    final freeLimit = ref.read(freeLimitProvider.notifier);
    final repo = ref.watch(libraryRepositoryProvider);
    final format = item.format.toUpperCase();

    final headline = item.isTone
        ? l10n.resultReadyRingtone
        : l10n.resultReadyAudio(format);
    final job = ref.watch(jobProvider);
    final madeNow = job?.item?.id == item.id ? job!.draft : null;
    final fade = madeNow == null
        ? null
        : switch ((madeNow.fadeIn, madeNow.fadeOut)) {
            (true, true) => l10n.fadeBothLower,
            (true, false) => l10n.fadeInLower,
            (false, true) => l10n.fadeOutLower,
            (false, false) => l10n.noFadeLower,
          };
    final sub = item.isTone && fade != null
        ? l10n.resultSubRingtone(item.durationSec.round(), fade)
        : l10n.resultSubAudio;
    final meta = item.isTone
        ? l10n.resultMetaRingtone(Fmt.duration(item.durationSec))
        : item.bitrateKbps > 0
        ? l10n.metaFormatBitrateSize(
            format,
            item.bitrateKbps,
            Fmt.bytes(item.bytes),
          )
        : l10n.metaFormatSize(format, Fmt.bytes(item.bytes));

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NavHeader(
              title: l10n.resultTitle,
              leading: NavLeading.close,
              onLeading: _done,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s8,
                  AppSpace.screen,
                  AppSpace.s16,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.successSoft,
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        color: colors.success,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  Semantics(
                    header: true,
                    child: Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: text.largeTitle,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                  const SizedBox(height: AppSpace.s20),
                  Hero(
                    tag: 'item:${item.id}',
                    child: PlayerCard(
                      title: item.name,
                      meta: meta,
                      thumbnailPath: repo.thumbnailPath(item),
                      elapsedLabel: Fmt.duration(_played * item.durationSec),
                      durationLabel: Fmt.duration(item.durationSec),
                      peaks: _peaks,
                      played: _played,
                      playing: _playing,
                      onPlay: _togglePlay,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  _Stats(item: item),
                  const SizedBox(height: AppSpace.s16),
                  _CrossSellRow(
                    icon: item.isTone
                        ? PhosphorIcons.fileAudio()
                        : PhosphorIcons.bellRinging(),
                    title: item.isTone ? l10n.alsoSaveMp3 : l10n.makeItRingtone,
                    subtitle: item.isTone
                        ? l10n.alsoSaveMp3Detail
                        : l10n.makeItRingtoneDetail(config.ringtoneMaxSeconds),
                    onTap: _crossSell,
                  ),
                  if (_upsellCount != null && !isPro) ...[
                    const SizedBox(height: AppSpace.s12),
                    UpsellCard(count: _upsellCount!),
                  ],
                  if (_houseApp case final app?) ...[
                    const SizedBox(height: AppSpace.s12),
                    HouseCard(
                      app: app,
                      body: app.id == 'shrink' && item.sourceIsVideo
                          ? l10n.houseCardShrinkVideo(
                              Fmt.bytes(item.sourceBytes),
                            )
                          : app.pitch ?? l10n.moreFromMarberxShort,
                      onView: () {
                        ref
                            .read(analyticsProvider)
                            .houseCardTapped(app: app.id, screen: 'result');
                        openMarberxApp(ref, app, screen: 'result');
                      },
                      onHide: () => _hideHouseCard(app),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
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
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: item.isTone
                                ? l10n.setAsRingtone
                                : l10n.saveToFiles,
                            icon: item.isTone
                                ? PhosphorIcons.bellRinging()
                                : PhosphorIcons.downloadSimple(),
                            onPressed: _saving
                                ? null
                                : item.isTone
                                ? _setAsRingtone
                                : _saveToFiles,
                          ),
                        ),
                        const SizedBox(width: AppSpace.s12),
                        IconSquareButton(
                          icon: PhosphorIcons.export(),
                          semanticLabel: l10n.share,
                          onPressed: _share,
                        ),
                      ],
                    ),
                    if (!isPro) ...[
                      const SizedBox(height: AppSpace.s8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${l10n.freeLeftLine(freeLimit.remaining, freeLimit.total)} · ',
                            style: text.footnote.copyWith(color: colors.text2),
                          ),
                          InkWell(
                            onTap: () =>
                                openPaywall(context, PaywallSource.result),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                l10n.goUnlimited,
                                style: text.footnote.copyWith(
                                  color: colors.link,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    Widget cell(String value, String label, {bool highlight = false}) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: text.subhead.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight ? colors.success : colors.text,
              ),
            ),
            Text(label, style: text.footnote.copyWith(color: colors.text3)),
          ],
        ),
      );
    }

    Widget divider() => Container(width: 1, height: 36, color: colors.divider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s14),
      child: Row(
        children: [
          cell(
            Fmt.bytes(item.sourceBytes),
            item.sourceIsVideo ? l10n.statVideo : l10n.statAudio,
          ),
          divider(),
          cell(
            Fmt.bytes(item.bytes),
            item.isTone ? l10n.toneRingtone : item.format.toUpperCase(),
            highlight: true,
          ),
          divider(),
          cell(Fmt.took(item.tookMs), l10n.statTook),
        ],
      ),
    );
  }
}

class _CrossSellRow extends StatelessWidget {
  const _CrossSellRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, color: colors.accentOnSoft, size: 20),
              ),
              const SizedBox(width: AppSpace.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: text.caption.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIcons.caretRight(),
                color: colors.text3,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
