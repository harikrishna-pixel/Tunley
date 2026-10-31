import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/state.dart';
import '../../app/transitions.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../errors/error_screen.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.compatibility = false});

  /// E1 "Try compatibility mode".
  final bool compatibility;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _started = false;
  bool _left = false;
  Timer? _tick;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    afterRouteTransition(context, () {
      final draft = ref.read(draftProvider);
      if (draft != null) {
        unawaited(
          ref
              .read(jobProvider.notifier)
              .start(draft, compatibility: widget.compatibility),
        );
      }
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onJob(JobState? previous, JobState? next) {
    if (_left || next == null || next.backgrounded) return;
    if (previous?.status != JobStatus.running) return;
    switch (next.status) {
      case JobStatus.running:
        return;
      case JobStatus.succeeded:
        _left = true;
        context.pushReplacement('/result', extra: next.item);
      case JobStatus.failed:
        _left = true;
        if (next.error == EngineErrorCode.cancelled) {
          Navigator.of(context).maybePop();
        } else {
          context.pushReplacement(
            '/error',
            extra: ErrorArgs(
              next.error ?? EngineErrorCode.unknown,
              sourceName: next.draft.source.name,
              sourceBytes: next.draft.source.info.bytes,
              isVideo: next.draft.source.isVideo,
              percent: next.fraction > 0 ? (next.fraction * 100).round() : null,
              retriedCompatibility: next.compatibility,
              variableFrameRate:
                  next.draft.source.info.variableFrameRate ?? false,
            ),
          );
        }
    }
  }

  Future<void> _confirmCancel() async {
    final l10n = AppLocalizations.of(context);
    final percent = ((ref.read(jobProvider)?.fraction ?? 0) * 100).round();
    final stop = await AppAlert.show<bool>(
      context: context,
      title: l10n.stopTitle,
      body: l10n.stopBodyProgress(percent),
      actions: [
        AlertAction(l10n.keepConverting, false),
        AlertAction(l10n.stopConfirm, true, tone: AlertTone.destructive),
      ],
    );
    if (stop == true) {
      ref.read(analyticsProvider).taskCancelled(progressPct: percent);
      await ref.read(jobProvider.notifier).cancel();
    }
  }

  void _runInBackground() {
    ref.read(analyticsProvider).backgroundUsed(task: 'single');
    ref.read(jobProvider.notifier).sendToBackground();
    _left = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JobState?>(jobProvider, _onJob);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final job = ref.watch(jobProvider);
    final draft = job?.draft ?? ref.watch(draftProvider);
    final fraction = job?.status == JobStatus.running ? job!.fraction : 0.0;

    String? left;
    if (job != null && fraction > 0.02) {
      final elapsed = DateTime.now().difference(job.startedAt).inMilliseconds;
      final remaining = elapsed / fraction * (1 - fraction) / 1000;
      left = remaining < 1
          ? l10n.almostDone
          : l10n.secondsLeft(remaining.ceil());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Column(
            children: [
              NavHeader(title: l10n.convertingTitle, leading: NavLeading.none),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpace.s20),
                            Semantics(
                              liveRegion: true,
                              label: '${(fraction * 100).round()}%',
                              child: SizedBox.square(
                                // Shorter windows (iPhone Duo rotated) get a smaller ring.
                                dimension: (constraints.maxHeight * 0.4).clamp(
                                  160,
                                  250,
                                ),
                                child: CustomPaint(
                                  painter: _RingPainter(
                                    fraction: fraction,
                                    track: colors.surface2,
                                    progress: colors.accent,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 150,
                                          height: 70,
                                          child: FittedBox(
                                            child: Text(
                                              '${(fraction * 100).round()}%',
                                              style: text.timecode,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          left ?? '',
                                          style: text.caption.copyWith(
                                            color: colors.text2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s24),
                            if (draft != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.screen,
                                ),
                                child: AppCard(
                                  padding: const EdgeInsets.all(AppSpace.s12),
                                  child: Row(
                                    children: [
                                      MediaThumb(
                                        size: 56,
                                        path: draft.source.thumbnailPath,
                                        isVideo: draft.source.isVideo,
                                        heroTag: 'thumb:${draft.source.path}',
                                      ),
                                      const SizedBox(width: AppSpace.s14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              draft.isMerge
                                                  ? l10n.mergeConvertingTitle(
                                                      draft.inputs.length,
                                                    )
                                                  : l10n.convertingFile(
                                                      draft.source.name,
                                                      draft.outputFormat.label,
                                                    ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.subhead.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              draft.bitrateKbps > 0
                                                  ? l10n.convertingMeta(
                                                      draft.bitrateKbps,
                                                      draft.estimate().label,
                                                    )
                                                  : draft.estimate().label,
                                              style: text.caption.copyWith(
                                                color: colors.text2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpace.s16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.shieldCheck(),
                                  color: colors.text3,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpace.s6),
                                Flexible(
                                  child: Text(
                                    l10n.convertingPrivacy,
                                    style: text.caption.copyWith(
                                      color: colors.text3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.screen,
                              ),
                              child: Column(
                                children: [
                                  SecondaryButton(
                                    label: l10n.runInBackground,
                                    onPressed: job?.status == JobStatus.running
                                        ? _runInBackground
                                        : null,
                                  ),
                                  const SizedBox(height: AppSpace.s10),
                                  Text(
                                    l10n.backgroundCaption,
                                    textAlign: TextAlign.center,
                                    style: text.footnote.copyWith(
                                      color: colors.text3,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.s8),
                                  TextButton(
                                    onPressed: job?.status == JobStatus.running
                                        ? _confirmCancel
                                        : null,
                                    style: TextButton.styleFrom(
                                      foregroundColor: colors.danger,
                                      minimumSize: const Size(88, 44),
                                    ),
                                    child: Text(
                                      l10n.cancel,
                                      style: text.button.copyWith(
                                        color: colors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.s8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.progress,
  });

  final double fraction;
  final Color track;
  final Color progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0, 1),
      false,
      Paint()
        ..color = progress
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.progress != progress;
}
