import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../../app/monetization.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/pro_gate.dart';
import '../picker/picker_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final isPro = ref.watch(isProProvider);
    final goal = ref.watch(personalizationProvider).goal;
    ref.watch(freeLimitProvider);
    final freeLimit = ref.read(freeLimitProvider.notifier);
    final recent = ref.watch(recentItemsProvider).value ?? const [];

    void openPicker(PickerIntent intent) =>
        context.push('/pick', extra: intent);
    void select(String tool, {String entry = 'tile'}) =>
        ref.read(analyticsProvider).toolSelected(tool: tool, entry: entry);

    final (heroTitle, heroCta, heroIcon, heroIntent) = switch (goal) {
      UserGoal.ringtones => (
        l10n.heroTitleRingtone,
        l10n.heroCtaRingtone,
        PhosphorIcons.bellRinging(),
        const PickerIntent(
          tab: PickerTab.videos,
          mode: ConvertMode.ringtone,
          videosOnly: true,
        ),
      ),
      UserGoal.mp3FromVideos => (
        l10n.heroTitleMp3,
        l10n.heroCtaMp3,
        PhosphorIcons.filmSlate(),
        const PickerIntent(
          tab: PickerTab.videos,
          mode: ConvertMode.audioFile,
          videosOnly: true,
        ),
      ),
      UserGoal.convertFiles => (
        l10n.heroTitleConvert,
        l10n.heroCtaConvert,
        PhosphorIcons.arrowsLeftRight(),
        const PickerIntent(tab: PickerTab.audio, mode: ConvertMode.audioFile),
      ),
    };

    final tools = [
      (
        PhosphorIcons.filmSlate(),
        l10n.toolVideoToMp3,
        false,
        () {
          select('video_to_mp3');
          openPicker(
            const PickerIntent(
              tab: PickerTab.videos,
              mode: ConvertMode.audioFile,
              videosOnly: true,
            ),
          );
        },
      ),
      (
        PhosphorIcons.arrowsLeftRight(),
        l10n.toolConvertFormat,
        false,
        () {
          select('convert');
          openPicker(
            const PickerIntent(
              tab: PickerTab.audio,
              mode: ConvertMode.audioFile,
            ),
          );
        },
      ),
      (
        PhosphorIcons.scissors(),
        l10n.toolTrimFade,
        false,
        () {
          select('trim');
          openPicker(const PickerIntent(openTrim: true));
        },
      ),
      (
        PhosphorIcons.arrowsMerge(),
        l10n.toolMerge,
        !isPro,
        () {
          select('merge');
          if (isPro) {
            openPicker(const PickerIntent(purpose: PickerPurpose.merge));
          } else {
            ProGateSheet.show(
              context,
              feature: l10n.toolMerge,
              analyticsFeature: 'merge',
              detail: l10n.p2DetailMerge,
            );
          }
        },
      ),
      (
        PhosphorIcons.speakerHigh(),
        l10n.toolBoost,
        !isPro,
        () {
          select('boost');
          if (isPro) {
            openPicker(const PickerIntent(openTrim: true, openBoost: true));
          } else {
            ProGateSheet.show(
              context,
              feature: l10n.toolBoost,
              analyticsFeature: 'boost',
              detail: l10n.p2DetailBoost,
            );
          }
        },
      ),
      (
        PhosphorIcons.playlist(),
        l10n.toolBatch,
        !isPro,
        () {
          select('batch');
          if (isPro) {
            openPicker(
              const PickerIntent(tab: PickerTab.videos, videosOnly: true),
            );
          } else {
            ProGateSheet.show(
              context,
              feature: l10n.toolBatch,
              analyticsFeature: 'batch',
              detail: l10n.p2DetailBatch,
            );
          }
        },
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s12,
        AppSpace.screen,
        AppSpace.s24,
      ),
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(
                PhosphorIcons.waveform(PhosphorIconsStyle.bold),
                color: colors.heroText,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.homeTitle, style: text.largeTitle),
              ),
            ),
            if (!isPro)
              GestureDetector(
                onTap: () => openPaywall(context, PaywallSource.proChip),
                child: const ProChip(),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s18),
        HeroCard(
          eyebrow: l10n.heroEyebrow,
          title: heroTitle,
          buttonLabel: heroCta,
          buttonIcon: heroIcon,
          // Home hero stays the default CTA art — imported picks must not
          // appear here as a blank duration thumb (Janaki #65).
          showBars: true,
          onPressed: () {
            select(switch (goal) {
              UserGoal.ringtones => 'ringtone',
              UserGoal.mp3FromVideos => 'video_to_mp3',
              UserGoal.convertFiles => 'convert',
            }, entry: 'hero');
            openPicker(heroIntent);
          },
        ),
        const SizedBox(height: AppSpace.s18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(l10n.homeTools, style: text.sectionTitle)),
            if (!isPro)
              FreeCounter(
                remaining: freeLimit.remaining,
                total: freeLimit.total,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s10),
        _ToolGrid(tools: tools),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s18),
          Row(
            children: [
              Expanded(child: Text(l10n.homeRecent, style: text.sectionTitle)),
              // Hide with a single file; show once 2+ are in Recent.
              if (recent.length >= 2)
                TextLinkButton(
                  label: l10n.seeAll,
                  onPressed: () => context.go('/files'),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          ListGroup(
            children: [for (final item in recent) RecentRow(item: item)],
          ),
        ],
      ],
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.tools});

  final List<(IconData, String, bool, VoidCallback)> tools;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tools.length; i += 3) {
      if (i > 0) rows.add(const SizedBox(height: AppSpace.s8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + 3 && j < tools.length; j++) ...[
                if (j > i) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: ToolTile(
                    icon: tools[j].$1,
                    label: tools[j].$2,
                    showProBadge: tools[j].$3,
                    onTap: tools[j].$4,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Library row with a play shortcut. Opens the item's Result.
class RecentRow extends ConsumerWidget {
  const RecentRow({super.key, required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final repo = ref.watch(libraryRepositoryProvider);
    final meta = item.isTone
        ? l10n.metaRingtone(Fmt.duration(item.durationSec))
        : item.bitrateKbps > 0
        ? l10n.metaFormatBitrateSize(
            item.format.toUpperCase(),
            item.bitrateKbps,
            Fmt.bytes(item.bytes),
          )
        : l10n.metaFormatSize(item.format.toUpperCase(), Fmt.bytes(item.bytes));
    return InkWell(
      onTap: () => context.push('/item', extra: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s10,
        ),
        child: Row(
          children: [
            MediaThumb(
              size: 44,
              path: repo.thumbnailPath(item),
              isVideo: item.sourceIsVideo,
            ),
            const SizedBox(width: AppSpace.s12),
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
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIcons.play(PhosphorIconsStyle.fill),
                size: 14,
                color: colors.accentOnSoft,
                semanticLabel: l10n.play,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
