import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';

class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  var _mode = _ConvertMode.audio;
  var _format = 0;
  var _quality = 0;
  var _rangeStart = 0.2;
  var _rangeEnd = 0.72;
  var _playing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final peaks = _samplePeaks();
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(l10n.galleryTitle, style: context.appText.navTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.s24,
        ),
        children: [
          SegmentedControl<ThemeMode>(
            items: [
              SegmentedItem(value: ThemeMode.light, label: l10n.themeLight),
              SegmentedItem(value: ThemeMode.dark, label: l10n.themeDark),
              SegmentedItem(value: ThemeMode.system, label: l10n.themeSystem),
            ],
            value: themeMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryAnalytics),
          const _AnalyticsLog(),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryButtons),
          PrimaryButton(
            label: l10n.continueAction,
            icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.s8),
          PrimaryButton(label: l10n.continueAction, onPressed: null),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              IconSquareButton(
                icon: PhosphorIcons.export(),
                semanticLabel: l10n.share,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpace.s12),
              TextLinkButton(label: l10n.notNow, muted: true, onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.gallerySegmented),
          SegmentedControl<_ConvertMode>(
            items: [
              SegmentedItem(value: _ConvertMode.audio, label: l10n.audioFile),
              SegmentedItem(value: _ConvertMode.ringtone, label: l10n.ringtone),
            ],
            value: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryFormats),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i != 0) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: FormatChip(
                    label: [l10n.formatMp3, l10n.formatM4a, l10n.formatFlac][i],
                    selected: _format == i,
                    showProBadge: i == 2,
                    onTap: () => setState(() => _format = i),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryQuality),
          RadioCard(
            title: l10n.highQuality,
            subtitle: l10n.highQualityDetail,
            sizeLabel: l10n.sizeEstimate,
            selected: _quality == 0,
            onTap: () => setState(() => _quality = 0),
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryTools),
          Row(
            children: [
              Expanded(
                child: ToolTile(
                  icon: PhosphorIcons.filmSlate(),
                  label: l10n.toolVideo,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: ToolTile(
                  icon: PhosphorIcons.arrowsLeftRight(),
                  label: l10n.toolConvert,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: ToolTile(
                  icon: PhosphorIcons.scissors(),
                  label: l10n.toolTrim,
                  showProBadge: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryBadges),
          const Wrap(
            spacing: AppSpace.s12,
            runSpacing: AppSpace.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProBadge(),
              ProChip(),
              FreeCounter(remaining: 2, total: 3),
              FreeCounter(remaining: 0, total: 3),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryStatus),
          StatusBox(message: l10n.originalSafe),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryHero),
          HeroCard(
            title: l10n.heroTitle,
            buttonLabel: l10n.heroButton,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryPlayer),
          PlayerCard(
            title: l10n.playerTitle,
            meta: l10n.playerMeta,
            elapsedLabel: l10n.playerElapsed,
            durationLabel: l10n.playerDuration,
            peaks: peaks,
            played: _playing ? 0.4 : 0.15,
            playing: _playing,
            onPlay: () => setState(() => _playing = !_playing),
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryWaveform),
          AppCard(
            child: WaveformView(
              peaks: peaks,
              start: _rangeStart,
              end: _rangeEnd,
              playhead: 0.4,
              onChanged: (start, end) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryTrial),
          AppCard(
            child: TrialTimeline(
              steps: [
                TrialStep(
                  icon: PhosphorIcons.lockOpen(),
                  title: l10n.trialStart,
                  dayLabel: l10n.trialToday,
                ),
                TrialStep(
                  icon: PhosphorIcons.bellRinging(),
                  title: l10n.trialReminder,
                  dayLabel: l10n.trialDay2,
                ),
                TrialStep(
                  icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                  title: l10n.trialCharge,
                  dayLabel: l10n.trialDay3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryToasts),
          Wrap(
            spacing: AppSpace.s8,
            children: [
              for (final (tone, message, action) in [
                (
                  ToastTone.success,
                  l10n.savedToFolder(l10n.homeTitle),
                  l10n.open,
                ),
                (ToastTone.success, l10n.toastRingtoneAdded, null),
                (ToastTone.success, l10n.toastCopied, null),
                (ToastTone.info, l10n.toastFreeLeft(2, 3), l10n.goPro),
                (ToastTone.info, l10n.toastWelcomePro, null),
                (ToastTone.warning, l10n.toastIcloud, null),
                (ToastTone.error, l10n.jobFailedToast, l10n.details),
              ])
                TextLinkButton(
                  label: message,
                  onPressed: () => TunelyToast.show(
                    context,
                    message: message,
                    tone: tone,
                    actionLabel: action,
                    onAction: action == null ? null : () {},
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          _Section(title: l10n.galleryOverlays),
          TextLinkButton(
            label: l10n.showSheet,
            onPressed: () {
              AppBottomSheet.show(
                context: context,
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sheetTitle, style: context.appText.dialogTitle),
                    const SizedBox(height: AppSpace.s8),
                    Text(l10n.sheetBody, style: context.appText.body),
                  ],
                ),
              );
            },
          ),
          TextLinkButton(
            label: l10n.showDialog,
            onPressed: () {
              AppDialog.show(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.dialogTitle, style: context.appText.dialogTitle),
                    const SizedBox(height: AppSpace.s8),
                    Text(l10n.dialogBody, style: context.appText.body),
                    const SizedBox(height: AppSpace.s16),
                    PrimaryButton(
                      label: l10n.stop,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s10),
      child: Text(title, style: context.appText.sectionTitle),
    );
  }
}

enum _ConvertMode { audio, ringtone }

List<double> _samplePeaks() {
  return [
    for (var i = 0; i < 48; i++)
      (0.35 + 0.55 * (0.5 + 0.5 * math.sin(i / 3)).abs()).clamp(0.15, 1.0),
  ];
}

/// Events recorded by [DebugAnalytics] (debug builds without a Mixpanel token).
class _AnalyticsLog extends ConsumerWidget {
  const _AnalyticsLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final colors = context.colors;
    final analytics = ref.watch(analyticsProvider);
    if (analytics is! DebugAnalytics) {
      return Text(
        l10n.galleryAnalyticsLive,
        style: text.caption.copyWith(color: colors.text2),
      );
    }
    return ValueListenableBuilder(
      valueListenable: analytics.events,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return Text(
            l10n.galleryAnalyticsEmpty,
            style: text.caption.copyWith(color: colors.text2),
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, props) in events.take(30))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$name  ',
                          style: text.footnote.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: props.isEmpty ? '' : props.toString(),
                          style: text.footnote.copyWith(color: colors.text2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
