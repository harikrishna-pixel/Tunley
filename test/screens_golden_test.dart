// Renders the core-flow screens in both themes for visual review against
// docs/handoff/Design/Screens_PNG. Run with:
//   TUNELY_GOLDENS=1 flutter test test/screens_golden_test.dart --update-goldens
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/adaptive.dart';
import 'package:tunely/app/account.dart';
import 'package:tunely/app/ads.dart';
import 'package:tunely/features/account/account_screen.dart';
import 'package:tunely/features/account/auth_screens.dart';
import 'package:tunely/features/account/invite_screen.dart';
import 'package:tunely/features/account/redeem_screen.dart';
import 'package:tunely/app/batch.dart';
import 'package:tunely/app/config.dart';
import 'package:tunely/features/ads/ad_break.dart';
import 'package:tunely/features/ads/ads_consent_screen.dart';
import 'package:tunely/features/more_apps/house_card.dart';
import 'package:tunely/features/more_apps/more_apps_screen.dart';
import 'package:tunely/app/merge.dart';
import 'package:tunely/features/batch/batch_screen.dart';
import 'package:tunely/features/merge/merge_screen.dart';
import 'package:tunely/features/prompts/milestone_dialog.dart';
import 'package:tunely/features/prompts/notification_prompt.dart';
import 'package:tunely/features/prompts/rating_dialog.dart';
import 'package:tunely/features/prompts/share_card_sheet.dart';
import 'package:tunely/features/prompts/update_dialog.dart';
import 'package:tunely/core/rules/milestone_rules.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/design_system.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/library/library_repository.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/features/convert/convert_screen.dart';
import 'package:tunely/features/errors/error_screen.dart';
import 'package:tunely/features/home/home_screen.dart';
import 'package:tunely/app/monetization.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/rules/paywall_triggers.dart';
import 'package:tunely/features/offers/offer_screens.dart';
import 'package:tunely/features/paywall/checkout.dart';
import 'package:tunely/features/paywall/daily_limit_dialog.dart';
import 'package:tunely/features/paywall/exit_offer_dialog.dart';
import 'package:tunely/features/paywall/paywall_screen.dart';
import 'package:tunely/features/paywall/pro_gate.dart';
import 'package:tunely/features/paywall/upsell.dart';
import 'package:tunely/features/help/help_screen.dart';
import 'package:tunely/features/my_files/my_files_screen.dart';
import 'package:tunely/features/onboarding/onboarding_screen.dart';
import 'package:tunely/features/preferences/preferences_screen.dart';
import 'package:tunely/features/ringtone_guide/ringtone_guide_screen.dart';
import 'package:tunely/features/settings/settings_screen.dart';
import 'package:tunely/core/rules/ringtone_rules.dart';
import 'package:tunely/features/picker/picker_screen.dart';
import 'package:tunely/features/progress/progress_screen.dart';
import 'package:tunely/features/result/result_screen.dart';
import 'package:tunely/features/trim/trim_screen.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

final _duo = Platform.environment['TUNELY_DUO'] == '1';
final _enabled = Platform.environment['TUNELY_GOLDENS'] == '1' || _duo;

/// (file suffix, physical size, pixel ratio, insets in physical px, dark).
typedef _Variant = (String, Size, double, FakeViewPadding, bool);

const _phone = <_Variant>[
  ('light', Size(780, 1688), 2, FakeViewPadding(top: 94, bottom: 68), false),
  ('dark', Size(780, 1688), 2, FakeViewPadding(top: 94, bottom: 68), true),
];

/// iPhone Duo at @3x, from the simulator's reported screen sizes (outer
/// 1398×2034, inner 2007×2853). The status bar strip sits on the right edge;
/// rotated, it moves to the top. Approximate until checked in Xcode 27.1.
const _duoVariants = <_Variant>[
  (
    'duo_outer',
    Size(1398, 2034),
    3,
    FakeViewPadding(right: 150, bottom: 60),
    false,
  ),
  (
    'duo_inner',
    Size(2007, 2853),
    3,
    FakeViewPadding(right: 150, bottom: 60),
    false,
  ),
  (
    'duo_inner_rotated',
    Size(2853, 2007),
    3,
    FakeViewPadding(top: 150, bottom: 60),
    false,
  ),
];

class _PreviewEngine extends FakeEngine {
  _PreviewEngine(super.outputDir);

  @override
  Future<List<double>> waveform(String path, {int buckets = 48}) async => [
    for (var i = 0; i < buckets; i++)
      (0.3 +
              0.6 *
                  (0.5 + 0.5 * math.sin(i / 2.3)) *
                  (0.6 + 0.4 * math.cos(i / 7)))
          .clamp(0.1, 1.0),
  ];

  @override
  Future<ConvertResult> convert(String jobId, ConvertRequest request) {
    scheduleMicrotask(() => emit(jobId, 0.65));
    return Completer<ConvertResult>().future;
  }
}

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await family('Plus Jakarta Sans', [
    for (final w in [400, 500, 600, 700, 800])
      'assets/fonts/PlusJakartaSans-$w.ttf',
  ]);
  for (final (name, file) in [
    ('PhosphorRegular', 'Phosphor'),
    ('PhosphorFill', 'Phosphor-Fill'),
    ('PhosphorBold', 'Phosphor-Bold'),
  ]) {
    await family('packages/phosphor_flutter/$name', [
      'packages/phosphor_flutter/lib/fonts/$file.ttf',
    ]);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (_) async => <String, Object?>{},
        );
    await _loadFonts();
  });

  final source = SourceFile(
    path: '/tmp/Dance_night.mov',
    name: 'Dance_night.mov',
    info: fakeInfo(),
  );
  final item = LibraryItem(
    id: 'preview',
    relPath: 'Library/Dance_night.mp3',
    name: 'Dance_night.mp3',
    format: 'mp3',
    bitrateKbps: 256,
    bytes: 1363148,
    durationSec: 42,
    sourceName: 'Dance_night.mov',
    sourceBytes: 86 * 1024 * 1024,
    sourceIsVideo: true,
    tookMs: 2600,
    createdAt: DateTime(2026, 10, 29),
  );

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    FutureOr<void> Function(ProviderContainer)? prepare,
    PurchasesService Function()? purchases,
  }) async {
    for (final (suffix, size, ratio, padding, dark)
        in _duo ? _duoVariants : _phone) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      tester.view.padding = padding;
      addTearDown(tester.view.reset);
      final engine = _PreviewEngine(Directory.systemTemp.createTempSync('g'));
      final container = testContainer(
        engine: engine,
        purchases: purchases?.call(),
      );
      addTearDown(container.dispose);
      container.read(pickedSourcesProvider.notifier).add(source);
      await tester.runAsync(() async => await prepare?.call(container));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTunelyTheme(AppColors.light),
            darkTheme: buildTunelyTheme(AppColors.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => AdaptivePage(
                child: Scaffold(
                  body:
                      screen is HomeScreen ||
                          screen is SettingsScreen ||
                          screen is MyFilesScreen
                      ? SafeArea(child: screen)
                      : screen,
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          _duo
              ? 'goldens/duo/${name}_$suffix.png'
              : 'goldens/${name}_$suffix.png',
        ),
      );
      await tester.pumpWidget(const SizedBox());
    }
  }

  void startDraft(ProviderContainer c, ConvertMode mode) {
    c.read(draftProvider.notifier).start(source, mode: mode);
    c.read(draftProvider.notifier).setPeaks([
      for (var i = 0; i < waveformBuckets; i++)
        (0.3 + 0.6 * (0.5 + 0.5 * math.sin(i / 2.3))).clamp(0.1, 1.0),
    ]);
  }

  testWidgets(
    'home',
    (t) => shoot(t, 'home', const HomeScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'picker',
    (t) => shoot(t, 'picker', const PickerScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'convert audio',
    (t) => shoot(
      t,
      'convert_audio',
      const ConvertScreen(),
      prepare: (c) => startDraft(c, ConvertMode.audioFile),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'convert ringtone',
    (t) => shoot(
      t,
      'convert_ringtone',
      const ConvertScreen(),
      prepare: (c) => startDraft(c, ConvertMode.ringtone),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'trim',
    (t) => shoot(
      t,
      'trim',
      const TrimScreen(),
      prepare: (c) => startDraft(c, ConvertMode.ringtone),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'progress',
    (t) => shoot(
      t,
      'progress',
      const ProgressScreen(),
      prepare: (c) => startDraft(c, ConvertMode.audioFile),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'result',
    (t) => shoot(t, 'result', ResultScreen(item: item)),
    skip: !_enabled,
  );
  for (final (name, args) in [
    (
      'e1_failed',
      const ErrorArgs(
        EngineErrorCode.decode,
        sourceName: 'Dance_night.mov',
        percent: 41,
      ),
    ),
    ('e2_no_space', const ErrorArgs(EngineErrorCode.noSpace, missingMb: 180)),
    (
      'e3_icloud',
      ErrorArgs(
        EngineErrorCode.icloud,
        sourceName: 'Festival.mov',
        sourceBytes: 1200 * 1024 * 1024,
      ),
    ),
    (
      'e4_protected',
      const ErrorArgs(
        EngineErrorCode.protected,
        sourceName: 'Apple Music track.m4p',
        isVideo: false,
      ),
    ),
    (
      'e4b_no_sound',
      const ErrorArgs(
        EngineErrorCode.noAudio,
        sourceName: 'Screen_recording.mov',
      ),
    ),
  ]) {
    testWidgets(
      name,
      (t) => shoot(t, name, ErrorScreen(args: args)),
      skip: !_enabled,
    );
  }
  testWidgets(
    'my files empty',
    (t) => shoot(t, 'my_files_empty', const MyFilesScreen()),
    skip: !_enabled,
  );
  Future<void> addItems(ProviderContainer c) async {
    final repo = c.read(libraryRepositoryProvider);
    final now = DateTime.now();
    for (final (i, name, format, tone, kbps) in [
      (0, 'Dance_night.mp3', 'mp3', null, 256),
      (1, 'Dance_night.m4r', 'm4r', ToneType.ringtone, 128),
      (2, 'Concert_clip.mp3', 'mp3', null, 320),
      (3, 'Morning_alarm.m4r', 'm4r', ToneType.alarm, 128),
    ]) {
      await repo.add(
        LibraryItem(
          id: 'g$i',
          relPath: 'Library/$name',
          name: name,
          format: format,
          bitrateKbps: kbps,
          bytes: 1363148 + i * 900000,
          durationSec: tone == null ? 42 : 30,
          toneType: tone,
          sourceName: 'Dance_night.mov',
          sourceBytes: 86 * 1024 * 1024,
          sourceIsVideo: true,
          tookMs: 2600,
          createdAt: now.subtract(Duration(days: i * 4)),
        ),
      );
    }
  }

  testWidgets(
    'my files',
    (t) => shoot(t, 'my_files', const MyFilesScreen(), prepare: addItems),
    skip: !_enabled,
  );
  testWidgets(
    'settings',
    (t) => shoot(t, 'settings', const SettingsScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'preferences',
    (t) => shoot(t, 'preferences', const PreferencesScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'help',
    (t) => shoot(t, 'help', const HelpScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'onboarding',
    (t) => shoot(t, 'onboarding', const OnboardingScreen()),
    skip: !_enabled,
  );
  monetizationGoldens(shoot);
  phase8Goldens(shoot, source, item);
  adsGoldens(shoot);
  accountGoldens(shoot);
  testWidgets(
    'guide',
    (t) => shoot(t, 'guide', RingtoneGuideScreen(item: item)),
    skip: !_enabled,
  );
}

class _DialogHost extends ConsumerStatefulWidget {
  const _DialogHost(this.open);

  final Future<void> Function(BuildContext context, WidgetRef ref) open;

  @override
  ConsumerState<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends ConsumerState<_DialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.open(context, ref),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void monetizationGoldens(
  Future<void> Function(
    WidgetTester,
    String,
    Widget, {
    FutureOr<void> Function(ProviderContainer)? prepare,
    PurchasesService Function()? purchases,
  })
  shoot,
) {
  testWidgets(
    'paywall',
    (t) => shoot(
      t,
      'p1_paywall',
      const PaywallScreen(source: PaywallSource.proChip),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'paywall no trial',
    (t) => shoot(
      t,
      'p1_paywall_no_trial',
      const PaywallScreen(source: PaywallSource.proChip),
      purchases: () => DemoPurchasesService(trialEligible: false),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'pro sheet',
    (t) => shoot(
      t,
      'p2_pro_sheet',
      _DialogHost(
        (context, ref) => ProGateSheet.show(
          context,
          feature: 'FLAC',
          analyticsFeature: 'flac',
          detail: 'Lossless, studio-quality audio',
          isFormat: true,
          freeAlternative: 'Use MP3 instead (free)',
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'daily limit',
    (t) => shoot(
      t,
      'p3_daily_limit',
      _DialogHost((context, ref) => showDailyLimit(context)),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'heavy user',
    (t) => shoot(
      t,
      'p5_heavy_user',
      _DialogHost((context, ref) => showHeavyUser(context, ref)),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'exit offer',
    (t) => shoot(
      t,
      'p6_exit_offer',
      _DialogHost((context, ref) async {
        final plans = await ref
            .read(purchasesServiceProvider)
            .plans(OfferingId.exit);
        await ref.read(paywallProvider.notifier).markShown(PaywallTrigger.p6);
        if (context.mounted) await showExitOffer(context, ref, plans.first);
      }),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'trial reminder',
    (t) => shoot(
      t,
      'p7_trial_reminder',
      const TrialReminderScreen(),
      prepare: (c) async {
        final service = c.read(purchasesServiceProvider);
        await service.purchase((await service.plans(OfferingId.main)).first);
      },
    ),
    skip: !_enabled,
  );
  testWidgets(
    'win back',
    (t) => shoot(t, 'p8_win_back', const WinBackScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'purchase failed',
    (t) => shoot(
      t,
      'p9_failed',
      _DialogHost(
        (context, ref) =>
            showPurchaseResult(context, ref, PurchaseResultKind.failed),
      ),
    ),
    skip: !_enabled,
  );
}

void phase8Goldens(
  Future<void> Function(
    WidgetTester,
    String,
    Widget, {
    FutureOr<void> Function(ProviderContainer)? prepare,
    PurchasesService Function()? purchases,
  })
  shoot,
  SourceFile source,
  LibraryItem item,
) {
  SourceFile named(String name, double seconds) => SourceFile(
    path: '/tmp/$name',
    name: name,
    info: fakeInfo(path: '/tmp/$name', seconds: seconds, hasVideo: false),
  );
  LibraryItem output(String name, int bytes) => LibraryItem(
    id: name,
    relPath: 'Library/$name',
    name: name,
    format: 'mp3',
    bitrateKbps: 256,
    bytes: bytes,
    durationSec: 42,
    sourceName: name,
    sourceBytes: 1,
    sourceIsVideo: true,
    tookMs: 1,
    createdAt: DateTime(2026, 10, 29),
  );
  BatchItem row(String name, BatchItemStatus status, {double f = 0}) =>
      BatchItem(
        source: SourceFile(path: '/tmp/$name', name: name, info: source.info),
        status: status,
        fraction: f,
        output: status == BatchItemStatus.done
            ? output(name.replaceAll(RegExp(r'\.\w+$'), '.mp3'), 4404019)
            : null,
        error: status == BatchItemStatus.failed ? EngineErrorCode.icloud : null,
      );

  testWidgets(
    'batch',
    (t) => shoot(
      t,
      'f4_batch',
      const BatchScreen(),
      prepare: (c) {
        c.read(batchProvider.notifier).debugState = BatchState(
          id: 'g',
          format: OutFormat.mp3,
          quality: Quality.high,
          startedAt: DateTime.now().subtract(const Duration(seconds: 12)),
          running: true,
          items: [
            row('Concert_clip.mov', BatchItemStatus.done),
            row('Birthday_party.mp4', BatchItemStatus.done),
            row('Beach_day.mov', BatchItemStatus.done),
            row('Festival.mov', BatchItemStatus.converting, f: 0.62),
            row('Guitar_session.mov', BatchItemStatus.waiting),
            row('Open_mic.mov', BatchItemStatus.waiting),
            row('Street_band.mov', BatchItemStatus.waiting),
            row('Sunset.mov', BatchItemStatus.waiting),
          ],
        );
      },
    ),
    skip: !_enabled,
  );
  testWidgets(
    'batch partial',
    (t) => shoot(
      t,
      's4_batch_partial',
      const BatchDoneScreen(),
      prepare: (c) {
        c.read(batchProvider.notifier).debugState = BatchState(
          id: 'g',
          format: OutFormat.mp3,
          quality: Quality.high,
          startedAt: DateTime.now(),
          items: [
            row('Festival.mov', BatchItemStatus.failed),
            for (final n in [
              'Concert_clip.mov',
              'Birthday_party.mp4',
              'Beach_day.mov',
              'Guitar_session.mov',
              'Open_mic.mov',
              'Street_band.mov',
              'Sunset.mov',
            ])
              row(n, BatchItemStatus.done),
          ],
        );
      },
    ),
    skip: !_enabled,
  );
  testWidgets(
    'merge',
    (t) => shoot(
      t,
      'f9_merge',
      const MergeScreen(),
      prepare: (c) => c.read(mergeProvider.notifier).add([
        named('Concert_clip.mp3', 72),
        named('Guitar_intro.m4a', 38),
        SourceFile(
          path: '/tmp/Dance_night.mov',
          name: 'Dance_night.mov',
          info: fakeInfo(seconds: 42),
        ),
        named('Birthday_song.mp3', 70),
      ]),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'notification pre-prompt',
    (t) => shoot(
      t,
      'm2_notify',
      _DialogHost(
        (context, ref) => AppBottomSheet.show<bool>(
          context: context,
          builder: (_) => const NotificationPrompt(reason: NotifyReason.batch),
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'rating',
    (t) => shoot(
      t,
      'm1_rating',
      _DialogHost(
        (context, ref) => AppDialog.show<int>(
          context: context,
          builder: (_) => const RatingDialog(),
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'update',
    (t) => shoot(
      t,
      'm4_update',
      _DialogHost(
        (context, ref) => AppDialog.show<bool>(
          context: context,
          builder: (_) => const UpdateDialog(
            version: '1.2',
            notes: [
              'Alarms and text tones in one tap',
              '2× faster video to MP3',
              'Fixes for long iCloud videos',
            ],
          ),
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'milestone',
    (t) => shoot(
      t,
      'm5_milestone',
      _DialogHost(
        (context, ref) => AppDialog.show<bool>(
          context: context,
          builder: (_) => const MilestoneDialog(
            milestone: FirstRingtoneMilestone(),
            ringtone: true,
          ),
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'share card',
    (t) => shoot(
      t,
      'm6_share_card',
      _DialogHost(
        (context, ref) => showShareCard(
          context,
          ref,
          LibraryItem(
            id: 'tone',
            relPath: 'Library/Dance_night_tone.m4r',
            name: 'Dance night.m4r',
            format: 'm4r',
            bitrateKbps: 128,
            bytes: 480000,
            durationSec: 30,
            toneType: ToneType.ringtone,
            sourceName: 'Dance_night.mov',
            sourceBytes: 1,
            sourceIsVideo: true,
            tookMs: 1,
            createdAt: DateTime(2026, 10, 29),
          ),
          entry: 'result',
        ),
      ),
    ),
    skip: !_enabled,
  );
}

void adsGoldens(
  Future<void> Function(
    WidgetTester,
    String,
    Widget, {
    FutureOr<void> Function(ProviderContainer)? prepare,
    PurchasesService Function()? purchases,
  })
  shoot,
) {
  testWidgets(
    'ad break',
    (t) => shoot(
      t,
      'a1_ad_break',
      _DialogHost(
        (context, ref) => AppDialog.show<void>(
          context: context,
          isDismissible: false,
          builder: (_) => const AdBreakDialog(title: 'Your MP3 is saved'),
        ),
      ),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'ads and tracking',
    (t) => shoot(t, 'a3_ads_tracking', const AdsConsentScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'more apps',
    (t) => shoot(t, 'x1_more_apps', const MoreAppsScreen()),
    skip: !_enabled,
  );
  testWidgets(
    'daily limit with rewarded',
    (t) => shoot(
      t,
      'p3_daily_limit_rewarded',
      _DialogHost((context, ref) => showDailyLimit(context)),
      prepare: (c) => c.read(adsProvider.notifier).start(),
    ),
    skip: !_enabled,
  );
  testWidgets(
    'house card',
    (t) => shoot(
      t,
      'r9d_house_card',
      Builder(
        builder: (context) {
          final config = ProviderScope.containerOf(context)
              .read(appConfigProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  HouseCard(
                    app: config.moreApps.first,
                    body: 'That video was 86 MB. Shrink makes videos smaller.',
                    onView: () {},
                    onHide: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    skip: !_enabled,
  );
}

void accountGoldens(
  Future<void> Function(
    WidgetTester,
    String,
    Widget, {
    FutureOr<void> Function(ProviderContainer)? prepare,
    PurchasesService Function()? purchases,
  })
  shoot,
) {
  Future<void> signIn(ProviderContainer c) async {
    await c
        .read(accountProvider.notifier)
        .signUp(
          firstName: 'Anna',
          lastName: 'Thomas',
          email: 'anna@example.com',
          password: 'password1',
        );
  }

  for (final (name, screen, signedIn) in [
    ('r1_invite_signed_out', const InviteScreen(), false),
    ('r2_invite', const InviteScreen(), true),
    ('r3_create_account', const SignUpScreen(), false),
    ('r4_sign_in', const SignInScreen(), false),
    ('r5_reset_password', const ResetPasswordScreen(), false),
    ('r6_account', const AccountScreen(), true),
    ('r7_delete_account', const DeleteAccountScreen(), true),
    (
      'r8_redeem',
      const RedeemScreen(args: RedeemArgs(code: 'ANNA7K', fromLink: true)),
      false,
    ),
  ]) {
    testWidgets(
      name,
      (t) => shoot(t, name, screen, prepare: signedIn ? signIn : null),
      skip: !_enabled,
    );
  }
}
