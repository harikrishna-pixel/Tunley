import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../app/transitions.dart';
import '../../core/design_system/design_system.dart';
import '../../core/format.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../convert/convert_screen.dart';
import '../paywall/pro_gate.dart';

class TrimScreen extends ConsumerStatefulWidget {
  const TrimScreen({super.key});

  @override
  ConsumerState<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends ConsumerState<TrimScreen> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _position;
  StreamSubscription<PlayerState>? _state;
  bool _ready = false;
  bool _playing = false;
  bool _started = false;
  double _playhead = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _playhead = ref.read(draftProvider)?.start ?? 0;
    afterRouteTransition(context, _prepare);
  }

  Future<void> _prepare() async {
    final draft = ref.read(draftProvider);
    if (draft == null) return;
    try {
      await _player.setFilePath(draft.source.path, preload: true);
    } catch (_) {
      return;
    }
    _position = _player.positionStream.listen((position) {
      final seconds = position.inMilliseconds / 1000;
      final current = ref.read(draftProvider);
      if (current == null || !mounted) return;
      if (_playing && seconds >= current.end) {
        _player.pause();
        _player.seek(_ms(current.start));
        setState(() => _playhead = current.start);
        return;
      }
      setState(() => _playhead = seconds);
    });
    _state = _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playing = state.playing);
    });
    await _player.seek(_ms(draft.start));
    if (mounted) setState(() => _ready = true);
  }

  Duration _ms(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  @override
  void dispose() {
    _position?.cancel();
    _state?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(ConvertDraft draft) async {
    if (!_ready) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_playhead < draft.start || _playhead >= draft.end - 0.05) {
      await _player.seek(_ms(draft.start));
    }
    ref.read(analyticsProvider).filePlayed(screen: 'trim');
    unawaited(_player.play());
  }

  Future<void> _nudge(ConvertDraft draft, double delta) async {
    final next = (_playhead + delta).clamp(draft.start, draft.end).toDouble();
    setState(() => _playhead = next);
    if (_ready) await _player.seek(_ms(next));
  }

  Future<void> _setBoost(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (value && !ref.read(isProProvider)) {
      await ProGateSheet.show(
        context,
        feature: l10n.volumeBoost,
        analyticsFeature: 'boost',
        detail: l10n.p2DetailBoost,
      );
      return;
    }
    ref.read(draftProvider.notifier).update((d) => d.copyWith(boost: value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final config = ref.watch(appConfigProvider);
    final isPro = ref.watch(isProProvider);
    final draft = ref.watch(draftProvider);
    if (draft == null) return Scaffold(backgroundColor: colors.bg);

    final total = draft.sourceSeconds <= 0 ? 1.0 : draft.sourceSeconds;
    final maxSpan = draft.isRingtone
        ? math.min(1.0, config.ringtoneMaxSeconds / total)
        : 1.0;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(
              title: l10n.trimFade,
              trailing: TextLinkButton(
                label: l10n.done,
                onPressed: () {
                  final draft = ref.read(draftProvider);
                  final config = ref.read(appConfigProvider);
                  if (draft != null) {
                    final fade = config.fadeDefaultSeconds;
                    ref
                        .read(analyticsProvider)
                        .trimApplied(
                          lengthS: draft.seconds,
                          fadeInS: draft.fadeIn ? fade : 0,
                          fadeOutS: draft.fadeOut ? fade : 0,
                          boostDb: draft.boost ? config.volumeBoostMaxDb : 0,
                        );
                  }
                  Navigator.of(context).maybePop();
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s8,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Display digits shrink to fit at large text sizes.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            Fmt.timecode(_playhead),
                            style: text.timecode,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: Text(
                          l10n.selectedRangeLong(
                            Fmt.duration(draft.start),
                            Fmt.duration(draft.end),
                            draft.seconds.round(),
                          ),
                          textAlign: TextAlign.end,
                          style: text.caption.copyWith(
                            color: colors.text2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s12,
                      vertical: AppSpace.s14,
                    ),
                    child: draft.peaks.isEmpty
                        ? const SizedBox(height: 120)
                        : WaveformView(
                            peaks: draft.peaks,
                            start: draft.start / total,
                            end: draft.end / total,
                            playhead: _playhead / total,
                            height: 120,
                            maxSpan: maxSpan,
                            onChanged: (start, end) {
                              ref
                                  .read(draftProvider.notifier)
                                  .update(
                                    (d) => d.copyWith(
                                      start: start * total,
                                      end: end * total,
                                    ),
                                  );
                              final s = start * total;
                              final e = end * total;
                              if (_playhead < s || _playhead > e) {
                                _nudge(draft.copyWith(start: s, end: e), 0);
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  TimeAxis(seconds: total, ticks: 4),
                  const SizedBox(height: AppSpace.s20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NudgeButton(
                        label: l10n.minusOneSecond,
                        semanticLabel: l10n.minusOneSecondLabel,
                        onTap: () => _nudge(draft, -1),
                      ),
                      const SizedBox(width: AppSpace.s24),
                      Semantics(
                        button: true,
                        label: _playing ? l10n.pause : l10n.play,
                        excludeSemantics: true,
                        child: Material(
                          color: colors.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _togglePlay(draft),
                            child: SizedBox(
                              width: 76,
                              height: 76,
                              child: PhosphorIcon(
                                _playing
                                    ? PhosphorIcons.pause(
                                        PhosphorIconsStyle.fill,
                                      )
                                    : PhosphorIcons.play(
                                        PhosphorIconsStyle.fill,
                                      ),
                                color: colors.accentText,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s24),
                      _NudgeButton(
                        label: l10n.plusOneSecond,
                        semanticLabel: l10n.plusOneSecondLabel,
                        onTap: () => _nudge(draft, 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s24),
                  ListGroup(
                    children: [
                      ToggleRow(
                        title: l10n.fadeIn,
                        subtitle: l10n.fadeSeconds(config.fadeDefaultSeconds),
                        value: draft.fadeIn,
                        onChanged: (v) => ref
                            .read(draftProvider.notifier)
                            .update((d) => d.copyWith(fadeIn: v)),
                      ),
                      ToggleRow(
                        title: l10n.fadeOut,
                        subtitle: l10n.fadeSeconds(config.fadeDefaultSeconds),
                        value: draft.fadeOut,
                        onChanged: (v) => ref
                            .read(draftProvider.notifier)
                            .update((d) => d.copyWith(fadeOut: v)),
                      ),
                      ToggleRow(
                        title: l10n.volumeBoost,
                        subtitle: isPro
                            ? l10n.volumeBoostDetailPro(config.volumeBoostMaxDb)
                            : l10n.volumeBoostDetail(config.volumeBoostMaxDb),
                        value: draft.boost,
                        onChanged: _setBoost,
                      ),
                    ],
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

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: StadiumBorder(side: BorderSide(color: colors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 52,
            child: Center(
              child: Text(
                label,
                style: context.appText.caption.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
