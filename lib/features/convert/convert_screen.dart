import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../app/transitions.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/rules/personalization.dart';
import '../../core/rules/preflight.dart';
import '../../core/rules/ringtone_rules.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../l10n/app_localizations.dart';
import '../common/edit_exit.dart';
import '../common/media_widgets.dart';
import '../errors/error_screen.dart';
import '../paywall/daily_limit_dialog.dart';
import '../paywall/pro_gate.dart';

const waveformBuckets = 64;

class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({super.key});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  bool _started = false;
  bool _checking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    afterRouteTransition(context, _loadPeaks);
  }

  Future<void> _loadPeaks() async {
    final draft = ref.read(draftProvider);
    if (draft == null || draft.peaks.isNotEmpty) return;
    try {
      final peaks = await ref
          .read(audioEngineProvider)
          .waveform(draft.source.path, buckets: waveformBuckets);
      if (!mounted) return;
      ref.read(draftProvider.notifier).setPeaks(peaks);
    } on EngineException {
      // The waveform is a preview only; conversion reports real errors.
    }
  }

  Future<void> _leave() async {
    if (!await confirmDiscardEdits(context) || !mounted) return;
    ref.read(draftProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickFormat(OutFormat format) async {
    final l10n = AppLocalizations.of(context);
    if (format.isPro && !ref.read(isProProvider)) {
      final useMp3 = await ProGateSheet.show(
        context,
        feature: l10n.featureFormat(format.label),
        analyticsFeature: format.name,
        detail: formatDetail(l10n, format),
        isFormat: true,
        freeAlternative: l10n.useMp3Free,
      );
      if (useMp3) _update((d) => d.copyWith(format: OutFormat.mp3));
      return;
    }
    _update((d) => d.copyWith(format: format));
  }

  Future<void> _pickTone(ToneType tone) async {
    final l10n = AppLocalizations.of(context);
    if (RingtoneRules.isPro(tone) && !ref.read(isProProvider)) {
      await ProGateSheet.show(
        context,
        feature: _toneLabel(l10n, tone),
        analyticsFeature: tone == ToneType.alarm ? 'alarm' : 'text_tone',
        detail: l10n.p2DetailTones,
      );
      return;
    }
    ref.read(draftProvider.notifier).setTone(tone);
  }

  void _update(ConvertDraft Function(ConvertDraft) change) {
    ref.read(draftProvider.notifier).update(change);
  }

  Future<void> _convert(ConvertDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final isPro = ref.read(isProProvider);
    final config = ref.read(appConfigProvider);
    final freeLimit = ref.read(freeLimitProvider.notifier);
    setState(() => _checking = true);
    try {
      await freeLimit.refresh();
      final limit = ref.read(freeLimitProvider);
      final free = await ref.read(audioEngineProvider).freeBytes();
      final outcome = Preflight.check(
        PreflightInput(
          canOpen: true,
          hasAudioTrack: draft.source.info.hasAudio,
          hasProtectedContent: draft.source.info.isProtected,
          icloudDownloadFailed: !draft.source.info.isLocal,
          freeBytes: free,
          estimateBytes: draft.estimate().bytes,
          isPro: isPro,
          requestsProFeature: draft.requestsPro,
          usedToday: limit.usedToday,
          rewardedToday: limit.rewardedToday,
          config: config,
        ),
      );
      if (!mounted) return;
      final block = outcome.block;
      if (block == null) {
        context.push('/progress');
        return;
      }
      switch (block) {
        case PreflightBlock.proFeature:
          await ProGateSheet.show(
            context,
            feature: draft.isRingtone
                ? _toneLabel(l10n, draft.tone)
                : draft.boost
                ? l10n.volumeBoost
                : l10n.featureFormat(draft.format.label),
            analyticsFeature: draft.isRingtone
                ? (draft.tone == ToneType.alarm ? 'alarm' : 'text_tone')
                : draft.boost
                ? 'boost'
                : draft.format.name,
          );
          return;
        case PreflightBlock.freeLimit:
          await _showLimit(config.freeConversionsPerDay);
          return;
        default:
          break;
      }
      final code = switch (block) {
        PreflightBlock.noSpace => EngineErrorCode.noSpace,
        PreflightBlock.noAudio => EngineErrorCode.noAudio,
        PreflightBlock.protected => EngineErrorCode.protected,
        PreflightBlock.icloud => EngineErrorCode.icloud,
        _ => EngineErrorCode.unreadable,
      };
      if (!mounted) return;
      final choice = await context.push<ErrorChoice>(
        '/error',
        extra: ErrorArgs(
          code,
          missingMb: outcome.missingMb,
          requiredBytes:
              draft.estimate().bytes * 2 + config.spaceMarginMb * 1024 * 1024,
          sourceName: draft.source.name,
          sourceBytes: draft.source.info.bytes,
          isVideo: draft.source.isVideo,
        ),
      );
      if (!mounted) return;
      if (choice == ErrorChoice.retry) {
        if (code == EngineErrorCode.noSpace) {
          context.push('/progress');
        } else {
          setState(() => _checking = false);
          await _convert(draft);
        }
      } else if (choice == ErrorChoice.another) {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showLimit(int total) => showDailyLimit(context);

  @override
  Widget build(BuildContext context) {
    ref.listen<ConvertDraft?>(draftProvider, (previous, next) {
      if (previous == null || next == null) return;
      if (previous.source.path != next.source.path) return;
      final changed =
          previous.format != next.format ||
          previous.quality != next.quality ||
          previous.mode != next.mode ||
          previous.tone != next.tone;
      if (!changed) return;
      ref
          .read(analyticsProvider)
          .settingsChanged(
            format: AnalyticsValues.format(next.outputFormat),
            quality: next.quality.name,
            mode: AnalyticsValues.mode(next.mode),
            toneType: next.isRingtone
                ? AnalyticsValues.toneType(next.tone)
                : null,
          );
    });
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final draft = ref.watch(draftProvider);
    if (draft == null) {
      return Scaffold(backgroundColor: colors.bg);
    }
    final isPro = ref.watch(isProProvider);
    final estimate = draft.estimate();

    final summaryLeft = draft.isRingtone
        ? l10n.summaryRingtone(draft.seconds.round())
        : draft.format.isLossless
        ? l10n.summaryLossless(draft.format.label, Fmt.duration(draft.seconds))
        : l10n.summaryLossy(
            draft.format.label,
            draft.bitrateKbps,
            Fmt.duration(draft.seconds),
          );
    final summaryRight = draft.isRingtone
        ? l10n.readyForIphone
        : l10n.summarySize(estimate.label, Fmt.bytes(draft.source.info.bytes));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NavHeader(
              title: draft.isRingtone
                  ? l10n.convertTitleRingtone
                  : l10n.convertTitleAudio,
              onLeading: _leave,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.s16,
                ),
                children: [
                  SourceCard(source: draft.source),
                  const SizedBox(height: AppSpace.s16),
                  SegmentedControl<ConvertMode>(
                    items: [
                      SegmentedItem(
                        value: ConvertMode.audioFile,
                        label: l10n.audioFile,
                      ),
                      SegmentedItem(
                        value: ConvertMode.ringtone,
                        label: l10n.ringtone,
                      ),
                    ],
                    value: draft.mode,
                    onChanged: (mode) =>
                        ref.read(draftProvider.notifier).setMode(mode),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AnimatedSize(
                    duration: AppMotion.of(
                      AppMotion.tab,
                      MediaQuery.disableAnimationsOf(context),
                    ),
                    alignment: Alignment.topCenter,
                    child: draft.isRingtone
                        ? _RingtoneSettings(
                            draft: draft,
                            isPro: isPro,
                            onTone: _pickTone,
                          )
                        : _AudioSettings(
                            draft: draft,
                            isPro: isPro,
                            onFormat: _pickFormat,
                          ),
                  ),
                ],
              ),
            ),
            ActionFooter(
              summary: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpace.s8,
                children: [
                  Text(
                    summaryLeft,
                    style: text.caption.copyWith(
                      color: colors.text2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    summaryRight,
                    style: text.caption.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              child: PrimaryButton(
                label: draft.isRingtone
                    ? l10n.createRingtone
                    : l10n.convertCta(draft.format.label),
                onPressed: _checking ? null : () => _convert(draft),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

String _toneLabel(AppLocalizations l10n, ToneType tone) => switch (tone) {
  ToneType.ringtone => l10n.toneRingtone,
  ToneType.alarm => l10n.toneAlarm,
  ToneType.textTone => l10n.toneTextTone,
};

class _AudioSettings extends ConsumerWidget {
  const _AudioSettings({
    required this.draft,
    required this.isPro,
    required this.onFormat,
  });

  final ConvertDraft draft;
  final bool isPro;
  final ValueChanged<OutFormat> onFormat;

  static const _rows = [
    [OutFormat.mp3, OutFormat.m4a, OutFormat.wav],
    [OutFormat.flac, OutFormat.aac, OutFormat.ogg],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final format = draft.format;
    final sourceKbps = draft.source.info.sourceBitrate;

    final qualities = [
      (Quality.standard, l10n.qualityStandard, l10n.qualityStandardDetail),
      (Quality.high, l10n.qualityHigh, l10n.qualityHighDetail),
      (Quality.best, l10n.qualityBest, l10n.qualityBestDetail),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l10n.convertFormat),
        for (final row in _rows) ...[
          Row(
            children: [
              for (var i = 0; i < row.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: FormatChip(
                    label: row[i].label,
                    selected: row[i] == format,
                    showProBadge: row[i].isPro && !isPro,
                    onTap: () => onFormat(row[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s10),
        ],
        const SizedBox(height: AppSpace.s6),
        SectionLabel(l10n.convertQuality),
        if (format.isLossless)
          RadioCard(
            title: l10n.qualityLossless,
            subtitle: format == OutFormat.wav
                ? l10n.qualityWavDetail
                : l10n.qualityFlacDetail,
            sizeLabel: draft.estimate().label,
            selected: true,
            onTap: () {},
          )
        else
          for (final (quality, title, detail) in qualities) ...[
            RadioCard(
              title: title,
              subtitle: detail,
              sizeLabel: draft.estimate(preset: quality.preset).label,
              selected: draft.quality == quality,
              onTap: () => ref
                  .read(draftProvider.notifier)
                  .update((d) => d.copyWith(quality: quality)),
            ),
            const SizedBox(height: AppSpace.s8),
          ],
        if (!format.isLossless &&
            sourceKbps != null &&
            sourceKbps < draft.quality.kbps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: Text(
              l10n.sourceBitrateCaption(sourceKbps),
              style: text.footnote.copyWith(color: colors.text3),
            ),
          ),
      ],
    );
  }
}

class _RingtoneSettings extends ConsumerWidget {
  const _RingtoneSettings({
    required this.draft,
    required this.isPro,
    required this.onTone,
  });

  final ConvertDraft draft;
  final bool isPro;
  final ValueChanged<ToneType> onTone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final config = ref.watch(appConfigProvider);
    final total = draft.sourceSeconds <= 0 ? 1.0 : draft.sourceSeconds;
    final maxSpan = (config.ringtoneMaxSeconds / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final tone in ToneType.values) ...[
              if (tone != ToneType.ringtone) const SizedBox(width: AppSpace.s8),
              Expanded(
                child: FormatChip(
                  label: _toneLabel(l10n, tone),
                  selected: draft.tone == tone,
                  showProBadge: RingtoneRules.isPro(tone) && !isPro,
                  onTap: () => onTone(tone),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectedPart,
                      style: text.caption.copyWith(
                        color: colors.text2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.selectedRange(
                        Fmt.duration(draft.start),
                        Fmt.duration(draft.end),
                        draft.seconds.round(),
                      ),
                      textAlign: TextAlign.end,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s12,
                  vertical: AppSpace.s6,
                ),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: draft.peaks.isEmpty
                    ? const SizedBox(height: 72)
                    : WaveformView(
                        peaks: draft.peaks,
                        start: draft.start / total,
                        end: draft.end / total,
                        maxSpan: maxSpan,
                        onChanged: (start, end) => ref
                            .read(draftProvider.notifier)
                            .update(
                              (d) => d.copyWith(
                                start: start * total,
                                end: end * total,
                              ),
                            ),
                      ),
              ),
              const SizedBox(height: AppSpace.s6),
              TimeAxis(seconds: total, ticks: 3),
              const SizedBox(height: AppSpace.s12),
              Row(
                children: [
                  Expanded(
                    child: TogglePill(
                      label: l10n.fadeIn,
                      value: draft.fadeIn,
                      onChanged: (v) => ref
                          .read(draftProvider.notifier)
                          .update((d) => d.copyWith(fadeIn: v)),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s10),
                  Expanded(
                    child: TogglePill(
                      label: l10n.fadeOut,
                      value: draft.fadeOut,
                      onChanged: (v) => ref
                          .read(draftProvider.notifier)
                          .update((d) => d.copyWith(fadeOut: v)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        StatusBox(
          message: l10n.ringtoneInfo(config.ringtoneMaxSeconds),
          tone: StatusTone.info,
        ),
      ],
    );
  }
}

/// `0:00 … 0:21 … 0:42` under a waveform.
class TimeAxis extends StatelessWidget {
  const TimeAxis({super.key, required this.seconds, required this.ticks});

  final double seconds;
  final int ticks;

  @override
  Widget build(BuildContext context) {
    final style = context.appText.footnote.copyWith(
      color: context.colors.text3,
      fontWeight: FontWeight.w700,
    );
    // Axis ticks are decorative (the range is spoken elsewhere); they grow
    // a little with Dynamic Type but never push each other off screen.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < ticks; i++)
            Text(Fmt.duration(seconds * i / (ticks - 1)), style: style),
        ],
      ),
    );
  }
}
