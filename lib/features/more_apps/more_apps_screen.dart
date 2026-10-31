import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/rules/house_card_policy.dart';
import '../../l10n/app_localizations.dart';

/// Opens a Marberx app's App Store page inside Tunely. Never a pop-up, never
/// a reward for installs (`05` §13).
Future<void> openMarberxApp(
  WidgetRef ref,
  MoreApp app, {
  required String screen,
  int position = 0,
}) async {
  ref
      .read(analyticsProvider)
      .moreAppsTapped(app: app.id, position: position, screen: screen);
  if (!app.hasStoreId) return;
  final engine = ref.read(audioEngineProvider);
  final opened = await engine.openAppStorePage(app.appStoreId);
  if (!opened) {
    await engine.openUrl('https://apps.apple.com/app/id${app.appStoreId}');
  }
}

IconData marberxIcon(String id) => switch (id) {
  'shrink' => PhosphorIcons.arrowsIn(PhosphorIconsStyle.bold),
  'biblehi' => PhosphorIcons.bookOpenText(),
  'imageresizer' => PhosphorIcons.crop(),
  _ => PhosphorIcons.appWindow(),
};

class MarberxIcon extends StatelessWidget {
  const MarberxIcon({super.key, required this.id, this.size = 52});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: colors.heroGradient,
          borderRadius: BorderRadius.circular(size * 0.26),
        ),
        child: Icon(marberxIcon(id), color: colors.heroText, size: size * 0.46),
      ),
    );
  }
}

/// More from Marberx (45), from Settings or a card.
class MoreAppsScreen extends ConsumerStatefulWidget {
  const MoreAppsScreen({super.key, this.entry = 'settings'});

  final String entry;

  @override
  ConsumerState<MoreAppsScreen> createState() => _MoreAppsScreenState();
}

class _MoreAppsScreenState extends ConsumerState<MoreAppsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).moreAppsOpened(entry: widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final apps = ref.watch(appConfigProvider).moreApps;
    final pickedId = HouseCardPolicy.pick([
      for (final a in apps) a.id,
    ], fromVideo: true);
    final picked = apps.where((a) => a.id == pickedId).firstOrNull;
    final others = apps.where((a) => a != picked).toList();

    Widget get(MoreApp app, int position, {required bool primary}) {
      final enabled = app.hasStoreId;
      return Semantics(
        button: true,
        enabled: enabled,
        label: l10n.moreAppsGet(app.name),
        excludeSemantics: true,
        child: Material(
          color: primary ? colors.accent : colors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.proChip),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.proChip),
            onTap: enabled
                ? () => openMarberxApp(
                    ref,
                    app,
                    screen: 'more_apps',
                    position: position,
                  )
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    enabled ? l10n.get : l10n.moreAppsSoon,
                    style: text.subhead.copyWith(
                      fontWeight: FontWeight.w800,
                      color: primary ? colors.accentText : colors.accentOnSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: l10n.moreAppsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  Text(
                    l10n.moreAppsIntro,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                  if (picked != null) ...[
                    const SizedBox(height: AppSpace.s20),
                    SectionLabel(l10n.moreAppsPicked),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpace.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MarberxIcon(id: picked.id, size: 68),
                              const SizedBox(width: AppSpace.s16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(picked.name, style: text.navTitle),
                                    if (picked.pitch != null)
                                      Text(
                                        picked.pitch!,
                                        style: text.subhead.copyWith(
                                          color: colors.text2,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.s8),
                              get(picked, 0, primary: true),
                            ],
                          ),
                          if (picked.reason != null) ...[
                            const SizedBox(height: AppSpace.s14),
                            Text(
                              picked.reason!,
                              style: text.caption.copyWith(color: colors.text2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.s20),
                    SectionLabel(l10n.moreAppsAlso),
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < others.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, color: colors.divider),
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.s16),
                              child: Row(
                                children: [
                                  MarberxIcon(id: others[i].id),
                                  const SizedBox(width: AppSpace.s14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          others[i].name,
                                          style: text.subhead.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (others[i].pitch != null)
                                          Text(
                                            others[i].pitch!,
                                            style: text.caption.copyWith(
                                              color: colors.text2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.s8),
                                  get(others[i], i + 1, primary: false),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    l10n.moreAppsFooter,
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
