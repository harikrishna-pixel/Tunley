import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/account.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/account/account_api.dart';
import 'package:tunely/core/account/token_store.dart';
import 'package:tunely/core/analytics/events.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/rules/account_rules.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/features/account/auth_screens.dart';
import 'package:tunely/features/account/redeem_screen.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountRules', () {
    test('names, email and password as in 12 §2', () {
      expect(AccountRules.name(''), FieldError.required);
      expect(AccountRules.name('A' * 51), FieldError.tooLong);
      expect(AccountRules.name('Anna'), isNull);
      expect(AccountRules.email('anna@example'), FieldError.invalidEmail);
      expect(AccountRules.email('anna@example.com'), isNull);
      expect(AccountRules.password('short1'), FieldError.weakPassword);
      expect(AccountRules.password('longenough'), FieldError.weakPassword);
      expect(AccountRules.password('longenough1'), isNull);
    });
  });

  group('ReferralCode', () {
    test('first name, accents removed, max 6 letters + 2 safe characters', () {
      final rng = math.Random(1);
      for (final (name, prefix) in [
        ('Anna', 'ANNA'),
        ('Zoë', 'ZOE'),
        ('Praba', 'PRABA'),
        ('Maximiliano', 'MAXIMI'),
        ("D'Arcy", 'DARCY'),
      ]) {
        final code = ReferralCode.suggest(name, random: rng);
        expect(code, startsWith(prefix));
        expect(code.length, prefix.length + 2);
      }
    });

    test('fewer than 2 letters: TUNE + 4; no 0 O 1 I L in the random part', () {
      final rng = math.Random(2);
      for (var i = 0; i < 200; i++) {
        final code = ReferralCode.suggest('李', random: rng);
        expect(code, startsWith('TUNE'));
        expect(code.length, 8);
        expect(code.substring(4), isNot(matches(RegExp('[0O1IL]'))));
      }
    });

    test('links in and out', () {
      expect(
        ReferralCode.link('tunely.app', 'ANNA7K'),
        'https://tunely.app/i/ANNA7K',
      );
      expect(
        ReferralCode.fromLink(
          Uri.parse('https://tunely.app/i/anna7k'),
          domain: 'tunely.app',
        ),
        'ANNA7K',
      );
      expect(
        ReferralCode.fromLink(
          Uri.parse('https://evil.example/i/ANNA7K'),
          domain: 'tunely.app',
        ),
        isNull,
      );
      expect(ReferralCode.normalize(' an-na 7k '), 'ANNA7K');
    });
  });

  group('AccountController', () {
    late DemoAccountApi api;
    late MemoryTokenStore tokens;
    late FakeAnalytics analytics;
    late DemoPurchasesService purchases;

    ProviderContainer container() {
      final c = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('acc')),
        accountApi: api,
        tokens: tokens,
        analytics: analytics,
        purchases: purchases,
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      api = DemoAccountApi(random: math.Random(3));
      tokens = MemoryTokenStore();
      analytics = FakeAnalytics();
      purchases = DemoPurchasesService();
    });

    Future<AccountController> signedUp(ProviderContainer c) async {
      final account = c.read(accountProvider.notifier);
      await account.signUp(
        firstName: 'Anna',
        lastName: 'Thomas',
        email: 'anna@example.com',
        password: 'password1',
      );
      return account;
    }

    test(
      'sign-up signs in, stores tokens in the store, links RevenueCat',
      () async {
        final c = container();
        await signedUp(c);
        final user = c.read(accountProvider).user!;
        expect(user.referralCode, startsWith('ANNA'));
        expect(tokens.tokens, isNotNull);
        expect(purchases.loggedInAs, user.id);
        expect(
          analytics.names,
          containsAllInOrder([Events.signupStarted, Events.signupCompleted]),
        );
        for (final (_, props) in analytics.events) {
          for (final v in props.values) {
            expect('$v', isNot(contains('anna@')));
          }
        }
      },
    );

    test(
      'existing email and wrong password are reported, not thrown away',
      () async {
        final c = container();
        final account = await signedUp(c);
        await account.signOut();
        expect(c.read(accountProvider).signedIn, isFalse);

        await expectLater(
          account.signUp(
            firstName: 'Anna',
            lastName: 'T',
            email: 'ANNA@example.com',
            password: 'password1',
          ),
          throwsA(
            isA<AccountException>().having(
              (e) => e.error,
              'error',
              AccountError.emailExists,
            ),
          ),
        );
        expect(analytics.last(Events.signupFailed)['error'], 'email_exists');

        for (var i = 0; i < 5; i++) {
          await expectLater(
            account.logIn(email: 'anna@example.com', password: 'wrong'),
            throwsA(isA<AccountException>()),
          );
        }
        await expectLater(
          account.logIn(email: 'anna@example.com', password: 'password1'),
          throwsA(
            isA<AccountException>().having(
              (e) => e.error,
              'error',
              AccountError.rateLimited,
            ),
          ),
        );
      },
    );

    test(
      'expired access token refreshes silently; failed refresh signs out',
      () async {
        final c = container();
        final account = await signedUp(c);
        api.expireTokens();
        await account.refresh();
        expect(c.read(accountProvider).signedIn, isTrue);

        api
          ..expireTokens()
          ..revokeRefresh();
        await expectLater(account.refresh(), throwsA(isA<AccountException>()));
        expect(c.read(accountProvider).signedIn, isFalse);
        expect(tokens.tokens, isNull);
      },
    );

    test('session restores on the next launch from the Keychain', () async {
      final first = container();
      await signedUp(first);

      final second = container();
      second.read(accountProvider);
      await _settle();
      expect(second.read(accountProvider).user?.email, 'anna@example.com');
    });

    test('email_verified is noticed on the next /me', () async {
      final c = container();
      final account = await signedUp(c);
      api.verify('anna@example.com');
      await account.refresh();
      expect(c.read(accountProvider).user?.verified, isTrue);
      expect(analytics.names, contains(Events.emailVerified));
    });

    test('delete account needs the password and signs out', () async {
      final c = container();
      final account = await signedUp(c);
      await expectLater(
        account.deleteAccount('nope'),
        throwsA(
          isA<AccountException>().having(
            (e) => e.error,
            'error',
            AccountError.wrongPassword,
          ),
        ),
      );
      await account.deleteAccount('password1');
      expect(c.read(accountProvider).signedIn, isFalse);
      expect(analytics.names, contains(Events.accountDeleted));
      await expectLater(
        account.logIn(email: 'anna@example.com', password: 'password1'),
        throwsA(isA<AccountException>()),
      );
    });

    test(
      'friend redeems once per iPhone; first file qualifies the inviter',
      () async {
        final inviterSide = container();
        final inviter = await signedUp(inviterSide);
        api.verify('anna@example.com');
        final code = inviterSide.read(accountProvider).user!.referralCode;

        final friend = container();
        final referral = friend.read(referralProvider.notifier);
        final result = await referral.redeem(
          code.toLowerCase(),
          source: RedeemSource.deepLink,
        );
        expect(result.inviterFirstName, 'Anna');
        expect(analytics.last(Events.inviteCodeRedeemed), {
          'source': 'deep_link',
          'result': 'success',
        });
        await expectLater(
          referral.redeem(code, source: RedeemSource.manual),
          throwsA(
            isA<AccountException>().having(
              (e) => e.error,
              'error',
              AccountError.deviceUsed,
            ),
          ),
        );
        expect(
          analytics.last(Events.inviteCodeRedeemed)['result'],
          'device_used',
        );

        friend
            .read(draftProvider.notifier)
            .start(
              SourceFile(path: '/tmp/a.mov', name: 'a.mov', info: fakeInfo()),
              mode: ConvertMode.audioFile,
            );
        await friend
            .read(jobProvider.notifier)
            .start(friend.read(draftProvider)!);
        await _settle();
        expect(analytics.names, contains(Events.referralQualified));

        await inviter.refreshStats();
        final stats = inviterSide.read(accountProvider).stats!;
        expect(stats.joined, 1);
        expect(stats.earnedDays, 7);
      },
    );

    test('an unknown code is invalid', () async {
      final c = container();
      await expectLater(
        c
            .read(referralProvider.notifier)
            .redeem('NOPE22', source: RedeemSource.manual),
        throwsA(
          isA<AccountException>().having(
            (e) => e.error,
            'error',
            AccountError.invalidCode,
          ),
        ),
      );
    });
  });

  group('Forms', () {
    Widget host(ProviderContainer c, Widget child) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildTunelyTheme(AppColors.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

    testWidgets('sign-up: inline errors, offline keeps what was typed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final api = DemoAccountApi()..offline = true;
      final c = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('f')),
        accountApi: api,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(c, const SignUpScreen()));

      await tester.tap(find.text('Create account').last);
      await tester.pump();
      expect(find.text('Required'), findsNWidgets(4));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Anna');
      await tester.enterText(fields.at(1), 'Thomas');
      await tester.enterText(fields.at(2), 'anna@example.com');
      await tester.enterText(fields.at(3), 'password1');
      await tester.pump();
      expect(find.textContaining('ANNA'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Create account').last);
        await _settle();
      });
      await tester.pump();
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('anna@example.com'), findsOneWidget);
      expect(find.text('Thomas'), findsOneWidget);
    });

    testWidgets('sign-in shows one generic error', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final c = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('f')),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(c, const SignInScreen()));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'who@example.com');
      await tester.enterText(fields.at(1), 'whatever1');
      await tester.runAsync(() async {
        await tester.tap(find.text('Sign in').last);
        await _settle();
      });
      await tester.pump();
      expect(
        find.text(
          'Email or password is incorrect. Try again or reset your password.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('redeem from a link is prefilled; invalid shows 53c', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final c = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('f')),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          c,
          const RedeemScreen(args: RedeemArgs(code: 'ANNA7K', fromLink: true)),
        ),
      );
      expect(find.text('ANNA7K'), findsOneWidget);
      expect(find.text("Added from your friend's link"), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Apply code'));
        await _settle();
      });
      await tester.pump();
      expect(
        find.text(
          "This code isn't valid, or an invite was already used on this iPhone.",
        ),
        findsOneWidget,
      );
    });
  });
}
