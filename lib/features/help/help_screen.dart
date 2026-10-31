import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../errors/error_screen.dart';
import 'faq.dart';

/// Opens Mail with the app and iOS version. Never attaches the user's files.
Future<void> contactSupport(
  BuildContext context,
  WidgetRef ref, {
  String? errorCode,
  String? subject,
  String screen = 'help',
}) async {
  final analytics = ref.read(analyticsProvider);
  if (subject == null) {
    analytics.supportContacted(screen: screen);
  } else {
    analytics.feedbackSent();
  }
  final l10n = AppLocalizations.of(context);
  final engine = ref.read(audioEngineProvider);
  final info = await engine.appInfo();
  final body = StringBuffer(l10n.mailBody(info.version, info.osVersion));
  if (errorCode != null) body.write('\n$errorCode\n');
  final uri = Uri(
    scheme: 'mailto',
    path: supportEmail,
    query: _encodeQuery({
      'subject': subject ?? l10n.mailSubject,
      'body': body.toString(),
    }),
  );
  final opened = await engine.openUrl(uri.toString());
  if (!opened && context.mounted) {
    TunelyToast.show(
      context,
      message: l10n.supportCopied(supportEmail),
      tone: ToastTone.info,
    );
  }
}

String _encodeQuery(Map<String, String> params) => params.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key, this.initialSlug});

  final String? initialSlug;

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _search = TextEditingController();
  late String? _open = widget.initialSlug ?? 'ads';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final query = _search.text.trim().toLowerCase();
    final all = faqEntries(l10n);
    final entries = query.isEmpty
        ? all.take(featuredCount).toList()
        : all
              .where(
                (e) =>
                    e.question.toLowerCase().contains(query) ||
                    e.answer.toLowerCase().contains(query),
              )
              .toList();
    final showGarageBand =
        query.isEmpty ||
        l10n.gbTitle.toLowerCase().contains(query) ||
        query.contains('garage');

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NavHeader(title: l10n.helpTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s8,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    style: text.body,
                    decoration: InputDecoration(
                      hintText: l10n.helpSearch,
                      hintStyle: text.body.copyWith(color: colors.text3),
                      prefixIcon: Icon(
                        PhosphorIcons.magnifyingGlass(),
                        color: colors.text3,
                      ),
                      filled: true,
                      fillColor: colors.surface2,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpace.s14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.status),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  if (entries.isEmpty && !showGarageBand)
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.s16),
                      child: Text(
                        l10n.helpNoResults,
                        textAlign: TextAlign.center,
                        style: text.body.copyWith(color: colors.text2),
                      ),
                    )
                  else
                    ListGroup(
                      children: [
                        for (final entry in entries)
                          _FaqTile(
                            entry: entry,
                            expanded: _open == entry.slug,
                            onTap: () {
                              final opening = _open != entry.slug;
                              setState(
                                () => _open = opening ? entry.slug : null,
                              );
                              if (opening) {
                                ref
                                    .read(analyticsProvider)
                                    .helpArticleOpened(article: entry.slug);
                              }
                            },
                          ),
                        if (showGarageBand)
                          SettingsRow(
                            icon: PhosphorIcons.musicNotes(),
                            label: l10n.gbTitle,
                            onTap: () => context.push('/help/garageband'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            ActionFooter(
              child: _ContactButton(onTap: () => contactSupport(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIcons.chatCircle(),
                  color: colors.text,
                  size: 20,
                ),
                const SizedBox(width: AppSpace.s8),
                Flexible(
                  child: Text(
                    l10n.contactSupport,
                    textAlign: TextAlign.center,
                    style: context.appText.button.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    final duration = AppMotion.of(
      const Duration(milliseconds: 200),
      MediaQuery.disableAnimationsOf(context),
    );
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s20,
            vertical: AppSpace.s16,
          ),
          child: AnimatedSize(
            duration: duration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.question,
                        style: text.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: duration,
                      child: PhosphorIcon(
                        PhosphorIcons.caretDown(),
                        color: colors.text2,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: AppSpace.s10),
                  Text(
                    entry.answer,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Help article for iOS 18 and older (`05` §7).
class GarageBandScreen extends ConsumerStatefulWidget {
  const GarageBandScreen({super.key});

  @override
  ConsumerState<GarageBandScreen> createState() => _GarageBandScreenState();
}

class _GarageBandScreenState extends ConsumerState<GarageBandScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final info = await ref.read(audioEngineProvider).appInfo();
      ref
          .read(analyticsProvider)
          .garagebandGuideOpened(iosVersion: info.osVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final steps = [
      l10n.gbStep1,
      l10n.gbStep2,
      l10n.gbStep3,
      l10n.gbStep4,
      l10n.gbStep5,
      l10n.gbStep6,
    ];
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: l10n.gbTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s8,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  Text(
                    l10n.gbIntro,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                  const SizedBox(height: AppSpace.s20),
                  for (var i = 0; i < steps.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            l10n.gbStepNumber(i + 1),
                            style: text.caption.copyWith(
                              color: colors.accentOnSoft,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.s14),
                        Expanded(child: Text(steps[i], style: text.body)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
