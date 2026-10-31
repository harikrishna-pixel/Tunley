import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/batch.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';

String batchFormatLabel(AppLocalizations l10n, BatchState batch) {
  final format = batch.format;
  return format.isLossless
      ? format.label
      : l10n.batchFormatBitrate(format.label, batch.quality.kbps);
}

/// Short reason on a failed batch row (S4).
String batchFailReason(AppLocalizations l10n, EngineErrorCode? code) {
  return switch (code) {
    EngineErrorCode.noAudio => l10n.failNoAudio,
    EngineErrorCode.protected => l10n.failProtected,
    EngineErrorCode.icloud => l10n.failICloud,
    EngineErrorCode.noSpace => l10n.failNoSpace,
    EngineErrorCode.interrupted => l10n.failInterrupted,
    EngineErrorCode.unreadable => l10n.failUnreadable,
    _ => l10n.failGeneric,
  };
}

/// Batch (21): overall progress, per-file rows, Stop / Run in background.
class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  Timer? _tick;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onBatch(BatchState? previous, BatchState? next) {
    if (_left || next == null || next.backgrounded) return;
    if ((previous?.running ?? false) && next.finished) {
      _left = true;
      context.pushReplacement('/batch/done');
    }
  }

  Future<void> _confirmStop() async {
    final l10n = AppLocalizations.of(context);
    final done = ref.read(batchProvider)?.done ?? 0;
    final stop = await AppAlert.show<bool>(
      context: context,
      title: l10n.batchStopTitle,
      body: l10n.batchStopBody(done),
      actions: [
        AlertAction(l10n.batchKeepGoing, false),
        AlertAction(l10n.stopConfirm, true, tone: AlertTone.destructive),
      ],
    );
    if (stop == true) await ref.read(batchProvider.notifier).stop();
  }

  void _runInBackground() {
    ref.read(analyticsProvider).backgroundUsed(task: 'batch');
    ref.read(batchProvider.notifier).sendToBackground();
    _left = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BatchState?>(batchProvider, _onBatch);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final batch = ref.watch(batchProvider);
    final os = ref.watch(appInfoProvider).value;
    final continued = os != null && osMajor(os) >= 26;
    if (batch == null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(child: NavHeader(title: l10n.batchTitle)),
      );
    }

    final fraction = batch.fraction;
    String? left;
    if (batch.running && fraction > 0.02) {
      final elapsed = DateTime.now().difference(batch.startedAt).inSeconds;
      final remaining = (elapsed / fraction * (1 - fraction)).ceil();
      left = remaining >= 90
          ? l10n.batchMinutesLeft((remaining / 60).ceil())
          : l10n.batchSecondsLeft(remaining.clamp(1, 90));
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && batch.running) {
          ref.read(batchProvider.notifier).sendToBackground();
        }
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Column(
            children: [
              NavHeader(title: l10n.batchTitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpace.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.batchSummary(
                              batch.done,
                              batch.total,
                              batchFormatLabel(l10n, batch),
                            ),
                            style: text.subhead.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.text2,
                            ),
                          ),
                          if (left != null)
                            Text(
                              left,
                              style: text.subhead.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.text2,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s10),
                      Semantics(
                        value: '${(fraction * 100).round()}%',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 10,
                            backgroundColor: colors.surface2,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (batch.paused)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    AppSpace.s12,
                    AppSpace.screen,
                    0,
                  ),
                  child: StatusBox(
                    message: l10n.batchPaused,
                    tone: StatusTone.warn,
                  ),
                ),
              const SizedBox(height: AppSpace.s12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    0,
                    AppSpace.screen,
                    AppSpace.s16,
                  ),
                  itemCount: batch.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s10),
                  itemBuilder: (context, index) =>
                      _BatchRow(item: batch.items[index], batch: batch),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.s8,
                ),
                child: Column(
                  children: [
                    Text(
                      continued
                          ? l10n.batchCaptionContinued
                          : l10n.batchCaptionLegacy,
                      textAlign: TextAlign.center,
                      style: text.footnote.copyWith(color: colors.text3),
                    ),
                    const SizedBox(height: AppSpace.s12),
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: _StopButton(
                            label: l10n.batchStop,
                            onPressed: batch.running && !batch.stopped
                                ? _confirmStop
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpace.s12),
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.runInBackground,
                            onPressed: batch.running ? _runInBackground : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              label,
              style: context.appText.button.copyWith(
                color: onPressed == null ? colors.text3 : colors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.item, required this.batch});

  final BatchItem item;
  final BatchState batch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final active = item.status == BatchItemStatus.converting;
    final output = item.output;
    final meta = switch (item.status) {
      BatchItemStatus.done when output != null => l10n.metaFormatSize(
        output.format.toUpperCase(),
        Fmt.bytes(output.bytes),
      ),
      BatchItemStatus.done => batch.format.label,
      BatchItemStatus.converting => l10n.batchConverting,
      BatchItemStatus.waiting => l10n.batchWaiting,
      BatchItemStatus.failed => batchFailReason(l10n, item.error),
    };
    final Widget trailing = switch (item.status) {
      BatchItemStatus.done => PhosphorIcon(
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        color: colors.success,
        size: 26,
      ),
      BatchItemStatus.converting => Text(
        '${(item.fraction * 100).round()}%',
        style: text.subhead.copyWith(
          color: colors.link,
          fontWeight: FontWeight.w800,
        ),
      ),
      BatchItemStatus.waiting => PhosphorIcon(
        PhosphorIcons.clock(),
        color: colors.text3,
        size: 24,
      ),
      BatchItemStatus.failed => PhosphorIcon(
        PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        color: colors.danger,
        size: 26,
      ),
    };
    return Semantics(
      label: '${item.source.name}, $meta',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: active
                ? colors.accent
                : item.status == BatchItemStatus.failed
                ? colors.danger
                : colors.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            MediaThumb(
              size: 54,
              path: item.source.thumbnailPath,
              isVideo: item.source.isVideo,
            ),
            const SizedBox(width: AppSpace.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    meta,
                    style: text.caption.copyWith(
                      color: item.status == BatchItemStatus.failed
                          ? colors.danger
                          : colors.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// S4 (40): batch finished, possibly with failures. Finished files are
/// already in My files; "Retry failed (n)" only re-runs the failed ones.
class BatchDoneScreen extends ConsumerWidget {
  const BatchDoneScreen({super.key});

  static const _completedShown = 2;

  void _done(BuildContext context, WidgetRef ref) {
    ref.read(batchProvider.notifier).clear();
    context.go('/files');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final batch = ref.watch(batchProvider);
    if (batch == null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: NavHeader(
            title: l10n.batchFinishedTitle,
            leading: NavLeading.none,
          ),
        ),
      );
    }
    final failed = [
      for (final i in batch.items)
        if (i.status == BatchItemStatus.failed) i,
    ];
    final done = [
      for (final i in batch.items)
        if (i.status == BatchItemStatus.done) i,
    ];
    final body = failed.isNotEmpty
        ? l10n.batchPartialBody(failed.length)
        : batch.stopped
        ? l10n.batchStoppedBody
        : l10n.batchAllDoneBody;

    Widget chip(String label, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s12,
        vertical: AppSpace.s6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.proChip),
      ),
      child: Text(
        label,
        style: text.caption.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Column(
            children: [
              NavHeader(
                title: l10n.batchFinishedTitle,
                leading: NavLeading.none,
                trailing: TextLinkButton(
                  label: l10n.done,
                  onPressed: () => _done(context, ref),
                ),
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
                    AppCard(
                      padding: const EdgeInsets.all(AppSpace.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpace.s8,
                            runSpacing: AppSpace.s8,
                            children: [
                              chip(
                                l10n.batchDoneChip(done.length),
                                colors.success,
                                colors.successSoft,
                              ),
                              if (failed.isNotEmpty)
                                chip(
                                  l10n.batchFailedChip(failed.length),
                                  colors.danger,
                                  colors.dangerSoft,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s10),
                          Text(
                            body,
                            style: text.body.copyWith(color: colors.text2),
                          ),
                        ],
                      ),
                    ),
                    if (failed.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.s20),
                      Text(
                        l10n.batchNeedsAttention,
                        style: text.subhead.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s10),
                      for (final item in failed) ...[
                        _BatchRow(item: item, batch: batch),
                        const SizedBox(height: AppSpace.s10),
                      ],
                    ],
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.s10),
                      Text(
                        l10n.batchCompleted,
                        style: text.subhead.copyWith(
                          color: colors.text2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s10),
                      _CompletedList(
                        items: done,
                        shown: _completedShown,
                        onMore: () => _done(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.s8,
                ),
                child: failed.isNotEmpty
                    ? PrimaryButton(
                        label: l10n.batchRetryFailed(failed.length),
                        onPressed: () {
                          ref
                              .read(analyticsProvider)
                              .batchRetryTapped(count: failed.length);
                          unawaited(
                            ref.read(batchProvider.notifier).retryFailed(),
                          );
                          context.pushReplacement('/batch');
                        },
                      )
                    : PrimaryButton(
                        label: l10n.batchOpenFiles,
                        onPressed: () => _done(context, ref),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedList extends StatelessWidget {
  const _CompletedList({
    required this.items,
    required this.shown,
    required this.onMore,
  });

  final List<BatchItem> items;
  final int shown;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final visible = items.take(shown).toList();
    final more = items.length - visible.length;
    Widget divider() => Divider(height: 1, color: colors.divider);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s14),
              child: Row(
                children: [
                  MediaThumb(
                    size: 44,
                    path: visible[i].source.thumbnailPath,
                    isVideo: visible[i].source.isVideo,
                  ),
                  const SizedBox(width: AppSpace.s14),
                  Expanded(
                    child: Text(
                      visible[i].output?.name ?? visible[i].source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (visible[i].output != null)
                    Text(
                      Fmt.bytes(visible[i].output!.bytes),
                      style: text.caption.copyWith(
                        color: colors.text2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (more > 0) ...[
            divider(),
            InkWell(
              onTap: onMore,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        '+$more',
                        style: text.caption.copyWith(
                          color: colors.accentOnSoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s14),
                    Text(
                      l10n.batchMoreFiles(more),
                      style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
