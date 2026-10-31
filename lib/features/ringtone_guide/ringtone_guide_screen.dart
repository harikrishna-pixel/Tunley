import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/library/library_repository.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../help/help_screen.dart';
import '../picker/picker_screen.dart';

/// iOS 26: share sheet "Use as Ringtone" in 3 steps. iOS 18 and older get
/// the GarageBand article (`05` §7).
// TODO(question #16): verify "Use as Ringtone" on a physical iOS 26 iPhone.
class RingtoneGuideScreen extends ConsumerStatefulWidget {
  const RingtoneGuideScreen({super.key, this.item});

  final LibraryItem? item;

  @override
  ConsumerState<RingtoneGuideScreen> createState() =>
      _RingtoneGuideScreenState();
}

class _RingtoneGuideScreenState extends ConsumerState<RingtoneGuideScreen> {
  int _step = 1;

  String get _ios => ref.read(appInfoProvider).value?.osVersion ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewed());
  }

  void _viewed() {
    final info = ref.read(appInfoProvider).value;
    if (info != null && osMajor(info) > 0 && osMajor(info) < 26) return;
    ref.read(analyticsProvider).guideStepViewed(step: _step, iosVersion: _ios);
  }

  void _setStep(int step) {
    setState(() => _step = step);
    _viewed();
  }

  Future<void> _share() async {
    final item = widget.item;
    if (item == null) {
      context.push(
        '/pick',
        extra: const PickerIntent(mode: ConvertMode.ringtone),
      );
      return;
    }
    final path = ref.read(libraryRepositoryProvider).absolutePath(item);
    ref.read(analyticsProvider).guideShareOpened(iosVersion: _ios);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    if (mounted) _setStep(2);
  }

  Future<void> _openSettings() async {
    await ref.read(audioEngineProvider).openUrl('app-settings:');
    if (mounted) _setStep(3);
  }

  void _back() {
    if (_step > 1) {
      _setStep(_step - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(appInfoProvider).value;
    if (info != null && osMajor(info) > 0 && osMajor(info) < 26) {
      return const GarageBandScreen();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final item = widget.item;
    final duration = AppMotion.of(
      const Duration(milliseconds: 200),
      MediaQuery.disableAnimationsOf(context),
    );

    final (title, body, primary, onPrimary) = switch (_step) {
      1 => (
        l10n.guide1Title,
        item == null ? l10n.guideNoFileBody : l10n.guide1Body,
        item == null ? l10n.makeRingtone : l10n.guideOpenShare,
        _share,
      ),
      2 => (
        l10n.guide2Title,
        l10n.guide2Body,
        l10n.guideOpenSettings,
        _openSettings,
      ),
      _ => (
        l10n.guide3Title,
        l10n.guide3Body,
        l10n.makeAnother,
        () {
          ref.read(analyticsProvider).guideCompleted(iosVersion: _ios);
          context.go('/home');
        },
      ),
    };

    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              NavHeader(title: l10n.guideTitle, onLeading: _back),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: Row(
                  children: [
                    for (var i = 1; i <= 3; i++) ...[
                      if (i > 1) const SizedBox(width: AppSpace.s8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: duration,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _step ? colors.accent : colors.surface2,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: ListView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s20,
                      AppSpace.screen,
                      AppSpace.s16,
                    ),
                    children: [
                      Text(
                        l10n.guideStep(_step),
                        style: text.caption.copyWith(
                          color: colors.link,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s10),
                      Semantics(
                        header: true,
                        child: Text(title, style: text.largeTitle),
                      ),
                      const SizedBox(height: AppSpace.s10),
                      Text(
                        body,
                        style: text.body.copyWith(color: colors.text2),
                      ),
                      const SizedBox(height: AppSpace.s20),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpace.s24),
                        child: switch (_step) {
                          1 => _ShareMock(item: item),
                          2 => _SettingsMock(item: item),
                          _ => const _DoneMock(),
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ActionFooter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(label: primary, onPressed: onPrimary),
                    const SizedBox(height: AppSpace.s4),
                    Center(
                      child: TextLinkButton(
                        label: l10n.guideGarageBandLink,
                        onPressed: () => context.push('/help/garageband'),
                      ),
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

class _ShareMock extends StatelessWidget {
  const _ShareMock({this.item});

  final LibraryItem? item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    Widget action(String label, IconData icon, {bool highlight = false}) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        decoration: BoxDecoration(
          color: highlight ? colors.accentSoft : null,
          border: highlight ? Border.all(color: colors.accent, width: 2) : null,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.subhead.copyWith(
                  color: highlight ? colors.accentOnSoft : colors.text2,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              icon,
              size: 20,
              color: highlight ? colors.accentOnSoft : colors.text2,
            ),
          ],
        ),
      );
    }

    return ExcludeSemantics(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.s14),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.row),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: colors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                    color: colors.heroText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.name ?? l10n.toneRingtone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.subhead.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item != null)
                        Text(
                          l10n.guideReady(Fmt.duration(item!.durationSec)),
                          style: text.footnote.copyWith(color: colors.text2),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s10),
          Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.row),
            ),
            child: Column(
              children: [
                action(l10n.guideShareSave, PhosphorIcons.folder()),
                action(
                  l10n.guideShareUse,
                  PhosphorIcons.bellRinging(),
                  highlight: true,
                ),
                action(l10n.guideShareAirdrop, PhosphorIcons.export()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMock extends StatelessWidget {
  const _SettingsMock({this.item});

  final LibraryItem? item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final name = item == null ? l10n.toneRingtone : Fmt.baseName(item!.name);
    Widget row(String label, {bool checked = false}) => SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: checked
                ? PhosphorIcon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: colors.accent,
                    size: 18,
                  )
                : null,
          ),
          Text(
            label,
            style: text.subhead.copyWith(
              fontWeight: checked ? FontWeight.w800 : FontWeight.w500,
              color: checked ? colors.text : colors.text2,
            ),
          ),
        ],
      ),
    );
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.guide2Path,
            style: text.footnote.copyWith(
              color: colors.text2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s14),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.row),
            ),
            child: Column(
              children: [row(name, checked: true), row(l10n.guide2Default)],
            ),
          ),
          const SizedBox(height: AppSpace.s10),
          Text(
            l10n.guide2Tip,
            style: text.footnote.copyWith(color: colors.text2),
          ),
        ],
      ),
    );
  }
}

class _DoneMock extends StatelessWidget {
  const _DoneMock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.successSoft,
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: colors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            l10n.guide3Card,
            textAlign: TextAlign.center,
            style: context.appText.subhead.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
