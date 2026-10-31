import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/config.dart';
import '../../app/monetization.dart';
import '../../core/rules/paywall_triggers.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';

/// O1–O5 on first launch. Skip on every question; answers apply immediately.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = 5;
  final _controller = PageController();
  int _page = 0;
  final _started = DateTime.now();

  Analytics get _analytics => ref.read(analyticsProvider);

  @override
  void initState() {
    super.initState();
    _analytics.onboardingStepViewed(step: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration get _duration => AppMotion.of(
    const Duration(milliseconds: 300),
    MediaQuery.disableAnimationsOf(context),
  );

  void _next() {
    final prefs = ref.read(preferencesProvider);
    if (_page == 1) {
      _analytics.onboardingQuestionAnswered(
        question: 'goal',
        answer: AnalyticsValues.goal(prefs.goal),
      );
    } else if (_page == 2) {
      _analytics.onboardingQuestionAnswered(
        question: 'frequency',
        answer: AnalyticsValues.frequency(prefs.frequency),
      );
    }
    if (_page == _pages - 1) {
      _analytics.onboardingCompleted(
        durationS: DateTime.now().difference(_started).inMilliseconds / 1000,
      );
      _finish();
      return;
    }
    _controller.nextPage(duration: _duration, curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    await ref.read(preferencesProvider.notifier).completeOnboarding();
    if (!mounted) return;
    final showP1 = ref
        .read(paywallProvider.notifier)
        .canShow(PaywallTrigger.p1);
    final router = GoRouter.of(context)..go('/home');
    if (showP1) router.push('/paywall', extra: PaywallSource.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final config = ref.watch(appConfigProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    final cta = switch (_page) {
      3 => l10n.soundsGood,
      4 => l10n.getStarted,
      _ => l10n.continueAction,
    };

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s8,
                AppSpace.s8,
                0,
              ),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Semantics(
                      label: l10n.onboardingStep(_page + 1, _pages),
                      child: _Dots(
                        count: _pages,
                        index: _page,
                        duration: _duration,
                      ),
                    ),
                    const Spacer(),
                    if (_page < _pages - 1)
                      TextLinkButton(
                        label: l10n.skip,
                        muted: true,
                        onPressed: () {
                          _analytics.onboardingSkipped(step: _page + 1);
                          _finish();
                        },
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) {
                  setState(() => _page = page);
                  _analytics.onboardingStepViewed(step: page + 1);
                },
                children: [
                  const _ValueDemo(),
                  _Choice(
                    title: l10n.o2Title,
                    body: l10n.o2Body,
                    footer: l10n.o2Footer,
                    options: [
                      _Option(
                        PhosphorIcons.bellRinging(),
                        l10n.goalRingtones,
                        l10n.goalRingtonesDetail,
                        prefs.goal == UserGoal.ringtones,
                        () => notifier.setGoal(UserGoal.ringtones),
                      ),
                      _Option(
                        PhosphorIcons.filmSlate(),
                        l10n.goalMp3,
                        l10n.goalMp3Detail,
                        prefs.goal == UserGoal.mp3FromVideos,
                        () => notifier.setGoal(UserGoal.mp3FromVideos),
                      ),
                      _Option(
                        PhosphorIcons.arrowsLeftRight(),
                        l10n.goalConvert,
                        l10n.goalConvertDetail,
                        prefs.goal == UserGoal.convertFiles,
                        () => notifier.setGoal(UserGoal.convertFiles),
                      ),
                    ],
                  ),
                  _Choice(
                    title: l10n.o3Title,
                    body: l10n.o3Body,
                    options: [
                      _Option(
                        null,
                        l10n.freqDaily,
                        l10n.freqDailyDetail,
                        prefs.frequency == UsageFrequency.everyDay,
                        () => notifier.setFrequency(UsageFrequency.everyDay),
                      ),
                      _Option(
                        null,
                        l10n.freqWeekly,
                        l10n.freqWeeklyDetail,
                        prefs.frequency == UsageFrequency.fewTimesAWeek,
                        () =>
                            notifier.setFrequency(UsageFrequency.fewTimesAWeek),
                      ),
                      _Option(
                        null,
                        l10n.freqRarely,
                        l10n.freqRarelyDetail,
                        prefs.frequency == UsageFrequency.onceInAWhile,
                        () =>
                            notifier.setFrequency(UsageFrequency.onceInAWhile),
                      ),
                    ],
                  ),
                  _Promises(freePerDay: config.freeConversionsPerDay),
                  const _Privacy(),
                ],
              ),
            ),
            ActionFooter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(label: cta, onPressed: _next),
                  if (_page == _pages - 1) ...[
                    const SizedBox(height: AppSpace.s12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.shieldCheck(),
                          size: 16,
                          color: colors.text3,
                        ),
                        const SizedBox(width: AppSpace.s6),
                        Text(
                          l10n.convertedOnIphone,
                          style: context.appText.caption.copyWith(
                            color: colors.text3,
                          ),
                        ),
                      ],
                    ),
                    // `12` §4: offered once, never a blocking step. A friend's
                    // code brings a free week, so P1 waits this time.
                    TextLinkButton(
                      label: l10n.onboardingInviteCode,
                      muted: true,
                      onPressed: () async {
                        await ref
                            .read(preferencesProvider.notifier)
                            .completeOnboarding();
                        if (!context.mounted) return;
                        GoRouter.of(context)
                          ..go('/home')
                          ..push('/redeem');
                      },
                    ),
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

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.duration,
  });

  final int count;
  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 26 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? colors.accent : colors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s24,
        AppSpace.screen,
        AppSpace.s16,
      ),
      children: children,
    );
  }
}

class _ValueDemo extends StatelessWidget {
  const _ValueDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return _Page(
      children: [
        SizedBox(
          height: 320,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 20,
                child: Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    width: 196,
                    height: 270,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.surface2, colors.border],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      boxShadow: colors.shadow,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: PhosphorIcon(
                            PhosphorIcons.filmSlate(PhosphorIconsStyle.fill),
                            color: colors.text3,
                            size: 56,
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s10,
                              vertical: AppSpace.s4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x80000000),
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                            ),
                            child: Text(
                              l10n.o1DemoFile,
                              style: text.footnote.copyWith(
                                color: colors.heroText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 130,
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(AppSpace.s16),
                  decoration: BoxDecoration(
                    gradient: colors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    boxShadow: colors.shadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0x33FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: PhosphorIcon(
                              PhosphorIcons.bellRinging(
                                PhosphorIconsStyle.fill,
                              ),
                              color: colors.heroText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.o1DemoTitle,
                                  style: text.subhead.copyWith(
                                    color: colors.heroText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  l10n.o1DemoMeta,
                                  style: text.footnote.copyWith(
                                    color: const Color(0xCCFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s14),
                      const _DemoBars(),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 168,
                top: 100,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: colors.shadow,
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    color: colors.accent,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        Text(l10n.o1Title, style: text.largeTitle),
        const SizedBox(height: AppSpace.s10),
        Text(l10n.o1Body, style: text.body.copyWith(color: colors.text2)),
      ],
    );
  }
}

class _DemoBars extends StatelessWidget {
  const _DemoBars();

  static const _h = [
    10,
    18,
    26,
    14,
    22,
    30,
    18,
    12,
    24,
    28,
    16,
    10,
    22,
    26,
    14,
    20,
    28,
    22,
    12,
    16,
    24,
    18,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          for (var i = 0; i < _h.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 3,
              height: _h[i].toDouble(),
              decoration: BoxDecoration(
                color: i < 13
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x66FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option {
  const _Option(
    this.icon,
    this.title,
    this.subtitle,
    this.selected,
    this.onTap,
  );

  final IconData? icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.body,
    required this.options,
    this.footer,
  });

  final String title;
  final String body;
  final List<_Option> options;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return _Page(
      children: [
        Text(title, style: text.largeTitle),
        const SizedBox(height: AppSpace.s8),
        Text(body, style: text.body.copyWith(color: colors.text2)),
        const SizedBox(height: AppSpace.s20),
        for (final option in options) ...[
          ChoiceCard(
            icon: option.icon,
            title: option.title,
            subtitle: option.subtitle,
            selected: option.selected,
            onTap: option.onTap,
          ),
          const SizedBox(height: AppSpace.s10),
        ],
        if (footer != null) ...[
          const SizedBox(height: AppSpace.s10),
          Text(
            footer!,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(color: colors.text2),
          ),
        ],
      ],
    );
  }
}

/// Large single-choice card with optional icon tile and a radio on the right.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AnimatedContainer(
            duration: AppMotion.of(
              const Duration(milliseconds: 150),
              MediaQuery.disableAnimationsOf(context),
            ),
            padding: const EdgeInsets.all(AppSpace.s18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.row),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: selected ? colors.accentText : colors.accentOnSoft,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.navTitle),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: text.caption.copyWith(color: colors.text2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                RadioMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Promises extends StatelessWidget {
  const _Promises({required this.freePerDay});

  final int freePerDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final items = [
      (PhosphorIcons.gift(), l10n.o4FreeTitle(freePerDay), l10n.o4FreeBody),
      (PhosphorIcons.clock(), l10n.o4AdsTitle, l10n.o4AdsBody),
      (PhosphorIcons.bell(), l10n.o4TrialTitle, l10n.o4TrialBody),
      (PhosphorIcons.shieldCheck(), l10n.o4DeviceTitle, l10n.o4DeviceBody),
    ];
    return _Page(
      children: [
        Text(l10n.o4Title, style: text.largeTitle),
        const SizedBox(height: AppSpace.s24),
        for (final (icon, title, body) in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.row),
                ),
                child: Icon(icon, size: 22, color: colors.accentOnSoft),
              ),
              const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.navTitle),
                    const SizedBox(height: 2),
                    Text(body, style: text.body.copyWith(color: colors.text2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
        ],
      ],
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    Widget tile({bool picked = false, bool dim = true}) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 0.92,
          child: Container(
            decoration: BoxDecoration(
              color: picked ? colors.accentSoft : colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              border: picked
                  ? Border.all(color: colors.accent, width: 3)
                  : null,
            ),
            child: Opacity(
              opacity: picked || !dim ? 1 : 0.5,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.image(PhosphorIconsStyle.fill),
                  color: picked ? colors.accentOnSoft : colors.text3,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _Page(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    tile(dim: false),
                    const SizedBox(width: AppSpace.s10),
                    tile(picked: true),
                    const SizedBox(width: AppSpace.s10),
                    tile(dim: false),
                  ],
                ),
                const SizedBox(height: AppSpace.s10),
                Row(
                  children: [
                    tile(),
                    const SizedBox(width: AppSpace.s10),
                    tile(),
                    const SizedBox(width: AppSpace.s10),
                    tile(),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s20,
                vertical: AppSpace.s10,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.hero),
                boxShadow: colors.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.lockSimple(),
                    color: colors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Text(
                    l10n.o5Pill,
                    style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        Text(l10n.o5Title, style: text.largeTitle),
        const SizedBox(height: AppSpace.s10),
        Text(l10n.o5Body, style: text.body.copyWith(color: colors.text2)),
      ],
    );
  }
}
