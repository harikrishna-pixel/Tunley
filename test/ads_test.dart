import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/ads.dart';
import 'package:tunely/app/app.dart';
import 'package:tunely/app/router.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/entitlements/paywall_memory.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/library/usage_store.dart';
import 'package:tunely/core/rules/ad_policy.dart';
import 'package:tunely/core/rules/free_limit.dart';
import 'package:tunely/core/rules/house_card_policy.dart';
import 'package:tunely/features/ads/ad_break.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

final _now = DateTime(2026, 10, 30, 12);

AdBreakRequest _req({
  AdMemory memory = const AdMemory(),
  DateTime? now,
  bool isPro = false,
  bool firstSession = false,
  int lifetime = 3,
  bool afterError = false,
  bool paywall = false,
  bool houseCard = false,
}) => AdBreakRequest(
  memory: memory,
  now: now ?? _now,
  isPro: isPro,
  adsEnabled: true,
  firstSession: firstSession,
  lifetimeConversions: lifetime,
  afterErrorInFlow: afterError,
  paywallInFlow: paywall,
  houseCardOnScreen: houseCard,
  firstSessionAds: false,
  minConversionsBeforeFirstAd: 3,
  everyNthConversion: 2,
  minSecondsBetween: 180,
  maxPerDay: 6,
);

HouseCardRequest _house({
  HouseCardMemory memory = const HouseCardMemory(),
  DateTime? now,
  DateTime? installed,
  bool isPro = false,
  int lifetime = 5,
  bool adBreak = false,
  bool upsell = false,
}) => HouseCardRequest(
  memory: memory,
  now: now ?? _now,
  installedAt: installed ?? _now.subtract(const Duration(days: 10)),
  isPro: isPro,
  success: true,
  lifetimeSuccesses: lifetime,
  adBreakThisSession: adBreak,
  upsellCardShowing: upsell,
  everyNthSuccess: 5,
  minDaysSinceInstall: 3,
);

void main() {
  group('AdPolicy', () {
    test('Pro, first session and before the 3rd conversion: never', () {
      expect(AdPolicy.canShowAdBreak(_req()), isTrue);
      expect(AdPolicy.canShowAdBreak(_req(isPro: true)), isFalse);
      expect(AdPolicy.canShowAdBreak(_req(firstSession: true)), isFalse);
      expect(AdPolicy.canShowAdBreak(_req(lifetime: 2)), isFalse);
    });

    test('never after an error, a paywall or with a house card', () {
      expect(AdPolicy.canShowAdBreak(_req(afterError: true)), isFalse);
      expect(AdPolicy.canShowAdBreak(_req(paywall: true)), isFalse);
      expect(AdPolicy.canShowAdBreak(_req(houseCard: true)), isFalse);
    });

    test('every 2nd conversion, 3 min apart, 6 a day', () {
      var memory = AdPolicy.afterAdBreak(const AdMemory(), _now);
      final later = _now.add(const Duration(minutes: 10));
      expect(
        AdPolicy.canShowAdBreak(_req(memory: memory, now: later)),
        isFalse,
      );
      memory = AdPolicy.afterConversion(memory);
      expect(
        AdPolicy.canShowAdBreak(_req(memory: memory, now: later)),
        isFalse,
      );
      memory = AdPolicy.afterConversion(memory);
      expect(AdPolicy.canShowAdBreak(_req(memory: memory, now: later)), isTrue);
      expect(
        AdPolicy.canShowAdBreak(
          _req(memory: memory, now: _now.add(const Duration(seconds: 179))),
        ),
        isFalse,
      );
      var capped = memory;
      for (var i = 0; i < 5; i++) {
        capped = AdPolicy.afterConversion(
          AdPolicy.afterConversion(AdPolicy.afterAdBreak(capped, _now)),
        );
      }
      expect(capped.adsOn(FreeLimit.dayKeyFor(_now)), 6);
      expect(
        AdPolicy.canShowAdBreak(_req(memory: capped, now: later)),
        isFalse,
      );
      final tomorrow = _now.add(const Duration(days: 1));
      expect(
        AdPolicy.canShowAdBreak(_req(memory: capped, now: tomorrow)),
        isTrue,
      );
    });

    test('rewarded at most 2 a day, never for Pro', () {
      bool offer(AdMemory m, {bool pro = false}) => AdPolicy.canOfferRewarded(
        memory: m,
        now: _now,
        isPro: pro,
        adsEnabled: true,
        rewardedMaxPerDay: 2,
      );
      var m = const AdMemory();
      expect(offer(m), isTrue);
      expect(offer(m, pro: true), isFalse);
      m = AdPolicy.afterReward(AdPolicy.afterReward(m, _now), _now);
      expect(offer(m), isFalse);
    });

    test('a reward adds exactly one free conversion', () {
      final day = FreeLimit.dayKeyFor(_now);
      final s = FreeLimit.recordRewarded(
        FreeLimitSnapshot(
          usedToday: 3,
          rewardedToday: 0,
          dayKey: day,
          maxDayKey: day,
        ),
      );
      expect(FreeLimit.isAtLimit(s, freePerDay: 3), isFalse);
      expect(s.rewardedToday, 1);
    });
  });

  group('HouseCardPolicy', () {
    test('every 5th success, not in the first 3 days, once a day', () {
      expect(HouseCardPolicy.canShow(_house()), isTrue);
      expect(HouseCardPolicy.canShow(_house(lifetime: 6)), isFalse);
      expect(
        HouseCardPolicy.canShow(
          _house(installed: _now.subtract(const Duration(days: 2))),
        ),
        isFalse,
      );
      final shown = HouseCardPolicy.shown(const HouseCardMemory(), _now);
      expect(HouseCardPolicy.canShow(_house(memory: shown)), isFalse);
      expect(
        HouseCardPolicy.canShow(
          _house(memory: shown, now: _now.add(const Duration(days: 1))),
        ),
        isTrue,
      );
    });

    test('never with an ad break or the P4 card', () {
      expect(HouseCardPolicy.canShow(_house(adBreak: true)), isFalse);
      expect(HouseCardPolicy.canShow(_house(upsell: true)), isFalse);
    });

    test('× hides 30 days; hidden 3 times, never again', () {
      var m = HouseCardPolicy.hidden(
        const HouseCardMemory(),
        _now,
        hideDays: 30,
      );
      expect(
        HouseCardPolicy.canShow(
          _house(memory: m, now: _now.add(const Duration(days: 29))),
        ),
        isFalse,
      );
      expect(
        HouseCardPolicy.canShow(
          _house(memory: m, now: _now.add(const Duration(days: 31))),
        ),
        isTrue,
      );
      m = HouseCardPolicy.hidden(
        HouseCardPolicy.hidden(m, _now, hideDays: 30),
        _now,
        hideDays: 30,
      );
      expect(
        HouseCardPolicy.canShow(
          _house(memory: m, now: _now.add(const Duration(days: 365))),
        ),
        isFalse,
      );
    });

    test('Pro sees it at most once a week; Shrink after a video', () {
      final shown = HouseCardPolicy.shown(const HouseCardMemory(), _now);
      expect(
        HouseCardPolicy.canShow(
          _house(
            memory: shown,
            isPro: true,
            now: _now.add(const Duration(days: 3)),
          ),
        ),
        isFalse,
      );
      expect(
        HouseCardPolicy.canShow(
          _house(
            memory: shown,
            isPro: true,
            now: _now.add(const Duration(days: 7)),
          ),
        ),
        isTrue,
      );
      const ids = ['shrink', 'biblehi', 'imageresizer'];
      expect(HouseCardPolicy.pick(ids, fromVideo: true), 'shrink');
      expect(HouseCardPolicy.pick(ids, fromVideo: false), 'biblehi');
    });
  });

  group('Ad flows', () {
    late FakeEngine engine;
    setUp(
      () => engine = FakeEngine(Directory.systemTemp.createTempSync('ads')),
    );

    Widget host(ProviderContainer c, Widget child) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildTunelyTheme(AppColors.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );

    testWidgets('42 first, the ad only after Continue, then counted', (
      tester,
    ) async {
      final ads = FakeAds();
      final container = testContainer(
        engine: engine,
        ads: ads,
        paywall: MemoryPaywallStore()..value = const PaywallMemory(sessions: 2),
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(adsProvider.notifier).start();
        final usage = container.read(usageStoreProvider);
        for (var i = 0; i < 3; i++) {
          await usage.recordSuccess(ringtone: false);
          await container.read(adsProvider.notifier).noteConversion();
        }
      });
      await tester.pumpWidget(
        host(
          container,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => maybeAdBreak(
                context,
                ref,
                trigger: AdBreakTrigger.save,
                formatLabel: 'MP3',
                ringtone: false,
              ),
              child: const Text('save'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('save'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Your MP3 is saved'), findsOneWidget);
      expect(ads.interstitials, 0);

      await tester.tap(find.text('Continue'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(ads.interstitials, 1);
      expect(container.read(adsProvider).adBreakThisSession, isTrue);

      // Next result right away: capped (every 2nd conversion, 3 min).
      await tester.tap(find.text('save'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Your MP3 is saved'), findsNothing);
    });

    testWidgets('no ad loaded: no notice at all', (tester) async {
      final ads = FakeAds()..loaded = false;
      final container = testContainer(
        engine: engine,
        ads: ads,
        paywall: MemoryPaywallStore()..value = const PaywallMemory(sessions: 2),
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(adsProvider.notifier).start();
        final usage = container.read(usageStoreProvider);
        for (var i = 0; i < 3; i++) {
          await usage.recordSuccess(ringtone: false);
        }
      });
      await tester.pumpWidget(
        host(
          container,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => maybeAdBreak(
                context,
                ref,
                trigger: AdBreakTrigger.done,
                formatLabel: 'MP3',
                ringtone: false,
              ),
              child: const Text('done'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('done'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Your MP3 is saved'), findsNothing);
    });

    test('rewarded +1 only from the reward callback', () async {
      final ads = FakeAds()..rewardOnShow = false;
      final container = testContainer(engine: engine, ads: ads);
      addTearDown(container.dispose);
      final controller = container.read(adsProvider.notifier);
      await controller.start();
      expect(await controller.watchRewarded(), isFalse);
      expect(container.read(freeLimitProvider).rewardedToday, 0);

      ads.rewardOnShow = true;
      expect(await controller.watchRewarded(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(freeLimitProvider).rewardedToday, 1);
      expect(controller.rewardedToday(), 1);
    });

    test('Pro never starts ads', () async {
      final purchases = DemoPurchasesService();
      final container = testContainer(engine: engine, purchases: purchases);
      addTearDown(container.dispose);
      await purchases.purchase((await purchases.plans(OfferingId.main)).first);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(isProProvider), isTrue);
      await container.read(adsProvider.notifier).start();
      expect(container.read(adsProvider).started, isFalse);
    });

    testWidgets('44 opens after launch; Continue asks iOS for tracking once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = createRouter();
      addTearDown(router.dispose);
      engine.tracking = 'notDetermined';
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TunelyApp(router: router),
        ),
      );
      // Launch with no offer due: UMP, then 44 on its own.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('thanks to a few ads'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(engine.trackingRequests, 1);
      expect(find.textContaining('thanks to a few ads'), findsNothing);
      expect(
        await container.read(usageStoreProvider).trackingPromptShown(),
        isTrue,
      );
    });
  });
}
