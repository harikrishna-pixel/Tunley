import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/monetization.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/rules/paywall_triggers.dart';
import 'package:tunely/core/rules/pricing.dart';
import 'package:tunely/features/paywall/paywall_screen.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

void main() {
  group('paywall caps with real state', () {
    test(
      'P1 once, exit offer once ever, one unrequested per session',
      () async {
        final container = testContainer();
        addTearDown(container.dispose);
        final paywall = container.read(paywallProvider.notifier);

        expect(paywall.canShow(PaywallTrigger.p1), isTrue);
        await paywall.markShown(PaywallTrigger.p1);
        expect(paywall.canShow(PaywallTrigger.p1), isFalse);

        // The one allowed pair: P1 close → P6.
        paywall.noteClosed();
        expect(paywall.canShow(PaywallTrigger.p6, closingP1: true), isTrue);
        await paywall.markShown(PaywallTrigger.p6);
        expect(paywall.canShow(PaywallTrigger.p6, closingP1: true), isFalse);

        // Session already used its unrequested paywall (P1).
        expect(paywall.canShow(PaywallTrigger.p5, lifetimeFiles: 10), isFalse);
      },
    );

    test(
      'never right after a paywall or an error; a new task resets',
      () async {
        final container = testContainer();
        addTearDown(container.dispose);
        final paywall = container.read(paywallProvider.notifier);
        paywall.noteClosed();
        expect(paywall.canShow(PaywallTrigger.p2), isFalse);
        paywall.noteTask();
        expect(paywall.canShow(PaywallTrigger.p2), isTrue);
        paywall.noteError();
        expect(paywall.canShow(PaywallTrigger.p3), isFalse);
      },
    );

    test('the exit offer timer survives a restart and expires', () async {
      final store = MemoryPaywallStore();
      final first = testContainer(paywall: store);
      await first.read(paywallProvider.notifier).markShown(PaywallTrigger.p6);
      first.dispose();

      final again = testContainer(paywall: store);
      addTearDown(again.dispose);
      final paywall = again.read(paywallProvider.notifier);
      expect(paywall.exitOfferResumable, isTrue);
      await paywall.finishExitOffer();
      expect(paywall.exitOfferResumable, isFalse);
      expect(paywall.canShow(PaywallTrigger.p6, closingP1: true), isFalse);
    });
  });

  test(
    'a trial purchase unlocks Pro and schedules the reminder 24 h early',
    () async {
      final reminder = FakeTrialReminder();
      final service = DemoPurchasesService();
      final container = testContainer(purchases: service, reminder: reminder);
      addTearDown(container.dispose);
      expect(container.read(isProProvider), isFalse);

      final yearly = (await service.plans(OfferingId.main)).first;
      final before = DateTime.now();
      await service.purchase(yearly);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(isProProvider), isTrue);

      final schedule = TrialSchedule(
        start: before,
        trialDays: yearly.trialDays!,
      );
      expect(
        schedule.chargeAt.difference(schedule.reminderAt),
        const Duration(hours: 24),
      );
    },
  );

  for (final eligible in [true, false]) {
    testWidgets('paywall copy when trial eligible = $eligible', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = testContainer(
        purchases: DemoPurchasesService(trialEligible: eligible),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTunelyTheme(AppColors.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PaywallScreen(source: PaywallSource.proChip),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(r'$0.58 / wk'), findsOneWidget);
      expect(find.text('SAVE 88%'), findsOneWidget);
      expect(find.text(r'$4.99 / wk'), findsOneWidget);
      expect(find.text(r'$39.99'), findsOneWidget);
      if (eligible) {
        expect(find.text('Start my free trial'), findsOneWidget);
        expect(
          find.text(r'Free for 3 days, then $29.99 / year. Cancel anytime.'),
          findsOneWidget,
        );
      } else {
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text(r'$29.99 / year. Cancel anytime.'), findsOneWidget);
        final words = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => (t.data ?? '').toLowerCase());
        expect(
          words.where((w) => w.contains('free') || w.contains('trial')),
          isEmpty,
        );
      }

      await tester.tap(find.text('Lifetime'));
      await tester.pump();
      expect(find.text('Buy lifetime'), findsOneWidget);
      expect(
        find.text(r'$39.99 one-time purchase. No subscription.'),
        findsOneWidget,
      );
    });
  }
}
