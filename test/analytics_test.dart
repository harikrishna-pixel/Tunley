import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/analytics_sync.dart';
import 'package:tunely/app/batch.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/core/analytics/analytics.dart';
import 'package:tunely/core/analytics/events.dart';
import 'package:tunely/core/analytics/values.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/core/rules/ringtone_rules.dart';

import 'support/fakes.dart';

typedef _Case = (String, Set<String>, void Function(Analytics));

final List<_Case> _cases = [
  // Onboarding & app.
  (Events.appOpened, {'source'}, (a) => a.appOpened(source: 'icon')),
  (
    Events.onboardingStepViewed,
    {'step'},
    (a) => a.onboardingStepViewed(step: 1),
  ),
  (
    Events.onboardingQuestionAnswered,
    {'question', 'answer'},
    (a) => a.onboardingQuestionAnswered(question: 'goal', answer: 'mp3'),
  ),
  (
    Events.onboardingCompleted,
    {'duration_s'},
    (a) => a.onboardingCompleted(durationS: 12.34),
  ),
  (Events.onboardingSkipped, {'step'}, (a) => a.onboardingSkipped(step: 2)),
  (
    Events.preferencesChanged,
    {'field', 'value'},
    (a) => a.preferencesChanged(field: 'goal', value: 'mp3'),
  ),
  (Events.permissionRequested, {'type'}, (a) => a.permissionRequested()),
  (
    Events.permissionResult,
    {'type', 'granted'},
    (a) => a.permissionResult(granted: true),
  ),
  // Core flow.
  (
    Events.toolSelected,
    {'tool', 'entry'},
    (a) => a.toolSelected(tool: 'trim', entry: 'tile'),
  ),
  (
    Events.filePicked,
    {'source', 'type', 'count', 'duration_s', 'size_mb'},
    (a) => a.filePicked(
      source: 'photos',
      type: 'video',
      count: 1,
      durationS: 42,
      sizeMb: 86,
    ),
  ),
  (
    Events.settingsChanged,
    {'format', 'quality', 'mode', 'tone_type'},
    (a) => a.settingsChanged(format: 'mp3', quality: 'high', mode: 'audio'),
  ),
  (
    Events.trimApplied,
    {'length_s', 'fade_in_s', 'fade_out_s', 'boost_db'},
    (a) => a.trimApplied(lengthS: 30, fadeInS: 2, fadeOutS: 2, boostDb: 0),
  ),
  (
    Events.taskStarted,
    {
      'task',
      'format',
      'quality',
      'mode',
      'input_type',
      'duration_s',
      'est_size_mb',
    },
    (a) => a.taskStarted(
      task: 'convert',
      format: 'mp3',
      quality: 'high',
      mode: 'audio',
      inputType: 'video',
      durationS: 42,
      estSizeMb: 1.3,
    ),
  ),
  (
    Events.taskCompleted,
    {
      'task',
      'format',
      'quality',
      'mode',
      'size_mb',
      'seconds_taken',
      'duration_s',
      'free_left',
    },
    (a) => a.taskCompleted(
      task: 'convert',
      format: 'mp3',
      quality: 'high',
      mode: 'audio',
      sizeMb: 1.3,
      secondsTaken: 2.6,
      durationS: 42,
      freeLeft: 2,
    ),
  ),
  (
    Events.taskFailed,
    {'task', 'error_type', 'progress_pct', 'format'},
    (a) => a.taskFailed(
      task: 'convert',
      errorType: 'decode',
      progressPct: 40,
      format: 'mp3',
    ),
  ),
  (
    Events.taskCancelled,
    {'progress_pct'},
    (a) => a.taskCancelled(progressPct: 10),
  ),
  (Events.backgroundUsed, {'task'}, (a) => a.backgroundUsed(task: 'single')),
  (Events.filePlayed, {'screen'}, (a) => a.filePlayed(screen: 'result')),
  (
    Events.fileSaved,
    {'destination', 'format'},
    (a) => a.fileSaved(destination: 'tunely_folder', format: 'mp3'),
  ),
  (
    Events.saveFolderChosen,
    {'is_icloud'},
    (a) => a.saveFolderChosen(isIcloud: true),
  ),
  (
    Events.fileShared,
    {'target', 'format', 'screen'},
    (a) => a.fileShared(target: 'airdrop', format: 'm4r', screen: 'result'),
  ),
  (Events.fileRenamed, {'format'}, (a) => a.fileRenamed(format: 'mp3')),
  (Events.fileDeleted, {'format'}, (a) => a.fileDeleted(format: 'mp3')),
  (
    Events.batchStarted,
    {'count', 'format'},
    (a) => a.batchStarted(count: 8, format: 'mp3'),
  ),
  (
    Events.batchCompleted,
    {'count', 'failed_count', 'seconds_taken'},
    (a) => a.batchCompleted(count: 8, failedCount: 1, secondsTaken: 40),
  ),
  (
    Events.mergeStarted,
    {'count', 'crossfade_s', 'format'},
    (a) => a.mergeStarted(count: 3, crossfadeS: 1, format: 'mp3'),
  ),
  (
    Events.mergeCompleted,
    {'count', 'length_s', 'seconds_taken'},
    (a) => a.mergeCompleted(count: 3, lengthS: 180, secondsTaken: 9),
  ),
  (
    Events.backgroundInterrupted,
    {'task', 'progress_pct', 'ios_major'},
    (a) =>
        a.backgroundInterrupted(task: 'batch', progressPct: 30, iosMajor: 18),
  ),
  (Events.jobResumed, {'task'}, (a) => a.jobResumed(task: 'batch')),
  // Ringtone.
  (
    Events.ringtoneCreated,
    {'tone_type', 'length_s', 'fade_in_s', 'fade_out_s'},
    (a) => a.ringtoneCreated(
      toneType: 'ringtone',
      lengthS: 30,
      fadeInS: 2,
      fadeOutS: 2,
    ),
  ),
  (
    Events.guideOpened,
    {'entry', 'ios_version'},
    (a) => a.guideOpened(entry: 'result', iosVersion: '26.0'),
  ),
  (
    Events.guideStepViewed,
    {'step', 'ios_version'},
    (a) => a.guideStepViewed(step: 1, iosVersion: '26.0'),
  ),
  (
    Events.guideShareOpened,
    {'ios_version'},
    (a) => a.guideShareOpened(iosVersion: '26.0'),
  ),
  (
    Events.guideCompleted,
    {'ios_version'},
    (a) => a.guideCompleted(iosVersion: '26.0'),
  ),
  (
    Events.garagebandGuideOpened,
    {'ios_version'},
    (a) => a.garagebandGuideOpened(iosVersion: '17.5'),
  ),
  // Monetization.
  (
    Events.paywallViewed,
    {'trigger', 'variant', 'goal', 'trial_eligible', 'feature'},
    (a) => a.paywallViewed(
      trigger: 'onboarding',
      variant: 'default',
      goal: 'ringtone',
      trialEligible: true,
    ),
  ),
  (
    Events.paywallClosed,
    {'trigger', 'seconds_on_screen'},
    (a) => a.paywallClosed(trigger: 'onboarding', secondsOnScreen: 4),
  ),
  (
    Events.planSelected,
    {'plan', 'trigger'},
    (a) => a.planSelected(plan: 'weekly', trigger: 'settings'),
  ),
  (
    Events.purchaseStarted,
    {'plan', 'trigger', 'price', 'currency'},
    (a) => a.purchaseStarted(
      plan: 'yearly',
      trigger: 'onboarding',
      price: 29.99,
      currency: 'USD',
    ),
  ),
  (
    Events.trialStarted,
    {'plan', 'trigger'},
    (a) => a.trialStarted(plan: 'yearly', trigger: 'onboarding'),
  ),
  (
    Events.purchaseSucceeded,
    {'plan', 'trigger', 'price', 'currency'},
    (a) => a.purchaseSucceeded(
      plan: 'lifetime',
      trigger: 'settings',
      price: 39.99,
      currency: 'USD',
    ),
  ),
  (
    Events.purchaseFailed,
    {'plan', 'trigger', 'error_code'},
    (a) => a.purchaseFailed(plan: 'yearly', trigger: 'x', errorCode: 'failed'),
  ),
  (
    Events.purchaseCancelled,
    {'plan', 'trigger'},
    (a) => a.purchaseCancelled(plan: 'yearly', trigger: 'x'),
  ),
  (Events.purchasePending, {'plan'}, (a) => a.purchasePending(plan: 'yearly')),
  (Events.purchaseOffline, {'action'}, (a) => a.purchaseOffline(action: 'buy')),
  (Events.restoreTapped, <String>{}, (a) => a.restoreTapped()),
  (
    Events.restoreResult,
    {'result', 'plan'},
    (a) => a.restoreResult(result: 'none'),
  ),
  (
    Events.limitReached,
    {'type', 'used_today'},
    (a) => a.limitReached(usedToday: 3),
  ),
  (
    Events.proFeatureTapped,
    {'feature'},
    (a) => a.proFeatureTapped(feature: 'flac'),
  ),
  (
    Events.freeAlternativeUsed,
    {'feature'},
    (a) => a.freeAlternativeUsed(feature: 'flac'),
  ),
  (
    Events.exitOfferShown,
    {'seconds_left'},
    (a) => a.exitOfferShown(secondsLeft: 600),
  ),
  (
    Events.exitOfferAccepted,
    {'seconds_left'},
    (a) => a.exitOfferAccepted(secondsLeft: 300),
  ),
  (Events.exitOfferExpired, {'seconds_left'}, (a) => a.exitOfferExpired()),
  (
    Events.trialReminderScheduled,
    {'hours_before_end'},
    (a) => a.trialReminderScheduled(hoursBeforeEnd: 24),
  ),
  (
    Events.trialReminderOpened,
    {'entry'},
    (a) => a.trialReminderOpened(entry: 'push'),
  ),
  (
    Events.manageSubscriptionTapped,
    {'screen'},
    (a) => a.manageSubscriptionTapped(screen: 'settings'),
  ),
  (
    Events.winbackShown,
    {'days_since_lapse'},
    (a) => a.winbackShown(daysSinceLapse: 20),
  ),
  (
    Events.winbackAccepted,
    {'days_since_lapse'},
    (a) => a.winbackAccepted(daysSinceLapse: 20),
  ),
  // Ads and cross-promotion.
  (
    Events.adBreakShown,
    {'trigger', 'conversions_today'},
    (a) => a.adBreakShown(trigger: 'save', conversionsToday: 3),
  ),
  (Events.adBreakContinue, <String>{}, (a) => a.adBreakContinue()),
  (
    Events.adRequested,
    {'format', 'provider'},
    (a) => a.adRequested(format: 'interstitial', provider: 'admob'),
  ),
  (
    Events.adLoaded,
    {'format', 'provider'},
    (a) => a.adLoaded(format: 'interstitial', provider: 'admob'),
  ),
  (
    Events.adFailed,
    {'format', 'provider', 'reason'},
    (a) => a.adFailed(format: 'rewarded', provider: 'admob', reason: 'no_fill'),
  ),
  (
    Events.adShown,
    {'format', 'provider', 'network'},
    (a) => a.adShown(format: 'interstitial', provider: 'admob'),
  ),
  (
    Events.adClosed,
    {'format', 'provider'},
    (a) => a.adClosed(format: 'interstitial', provider: 'admob'),
  ),
  (
    Events.adClicked,
    {'format', 'provider'},
    (a) => a.adClicked(format: 'interstitial', provider: 'admob'),
  ),
  (
    Events.rewardedOffered,
    {'rewarded_today'},
    (a) => a.rewardedOffered(rewardedToday: 0),
  ),
  (
    Events.rewardedEarned,
    {'rewarded_today'},
    (a) => a.rewardedEarned(rewardedToday: 1),
  ),
  (
    Events.removeAdsTapped,
    {'screen'},
    (a) => a.removeAdsTapped(screen: 'ad_break'),
  ),
  (Events.trackingPromptShown, <String>{}, (a) => a.trackingPromptShown()),
  (
    Events.trackingResult,
    {'status'},
    (a) => a.trackingResult(status: 'denied'),
  ),
  (
    Events.consentResult,
    {'status'},
    (a) => a.consentResult(status: 'obtained'),
  ),
  (
    Events.houseCardShown,
    {'app', 'screen'},
    (a) => a.houseCardShown(app: 'shrink', screen: 'result'),
  ),
  (
    Events.houseCardTapped,
    {'app', 'screen'},
    (a) => a.houseCardTapped(app: 'shrink', screen: 'result'),
  ),
  (
    Events.houseCardHidden,
    {'app', 'screen'},
    (a) => a.houseCardHidden(app: 'shrink', screen: 'result'),
  ),
  (
    Events.moreAppsOpened,
    {'entry'},
    (a) => a.moreAppsOpened(entry: 'settings'),
  ),
  (
    Events.moreAppsTapped,
    {'app', 'position', 'screen'},
    (a) => a.moreAppsTapped(app: 'shrink', position: 0, screen: 'more_apps'),
  ),
  // Self-marketing & prompts.
  (
    Events.ratingPromptShown,
    {'trigger', 'times_shown'},
    (a) => a.ratingPromptShown(trigger: 'ringtones_2', timesShown: 1),
  ),
  (
    Events.ratingPromptAnswered,
    {'stars', 'routed_to'},
    (a) => a.ratingPromptAnswered(stars: 5, routedTo: 'app_store'),
  ),
  (Events.feedbackSent, <String>{}, (a) => a.feedbackSent()),
  (
    Events.notificationPromptShown,
    {'context'},
    (a) => a.notificationPromptShown(context: 'batch'),
  ),
  (
    Events.milestoneReached,
    {'name'},
    (a) => a.milestoneReached(name: 'first_ringtone'),
  ),
  (
    Events.shareCardOpened,
    {'entry'},
    (a) => a.shareCardOpened(entry: 'milestone'),
  ),
  (
    Events.updatePromptShown,
    {'version'},
    (a) => a.updatePromptShown(version: '1.2.0'),
  ),
  (Events.updateTapped, {'version'}, (a) => a.updateTapped(version: '1.2.0')),
  (
    Events.helpArticleOpened,
    {'article'},
    (a) => a.helpArticleOpened(article: 'ads'),
  ),
  (
    Events.supportContacted,
    {'screen'},
    (a) => a.supportContacted(screen: 'help'),
  ),
  // Errors.
  (
    Events.errorShown,
    {'type', 'code'},
    (a) => a.errorShown(type: 'icloud', code: 'AUD-DEC-01'),
  ),
  (
    Events.errorRecoveryAction,
    {'type', 'action'},
    (a) => a.errorRecoveryAction(type: 'icloud', action: 'retry'),
  ),
  (Events.batchRetryTapped, {'count'}, (a) => a.batchRetryTapped(count: 1)),
  // Account and referral.
  (
    Events.inviteEntryOpened,
    {'source', 'signed_in'},
    (a) => a.inviteEntryOpened(source: 'settings', signedIn: false),
  ),
  (Events.signupStarted, <String>{}, (a) => a.signupStarted()),
  (Events.signupCompleted, <String>{}, (a) => a.signupCompleted()),
  (Events.signupFailed, {'error'}, (a) => a.signupFailed(error: 'network')),
  (Events.loginCompleted, <String>{}, (a) => a.loginCompleted()),
  (Events.loginFailed, {'error'}, (a) => a.loginFailed(error: 'network')),
  (
    Events.passwordResetRequested,
    <String>{},
    (a) => a.passwordResetRequested(),
  ),
  (Events.emailVerified, <String>{}, (a) => a.emailVerified()),
  (Events.accountDeleted, <String>{}, (a) => a.accountDeleted()),
  (
    Events.inviteLinkShared,
    {'channel'},
    (a) => a.inviteLinkShared(channel: 'messages'),
  ),
  (
    Events.inviteCodeRedeemed,
    {'source', 'result'},
    (a) => a.inviteCodeRedeemed(source: 'manual', result: 'success'),
  ),
  (Events.referralQualified, <String>{}, (a) => a.referralQualified()),
  (Events.referralRewarded, <String>{}, (a) => a.referralRewarded()),
];

/// Every event name in `08` › Event table.
Set<String> _specEvents() {
  final doc = File('docs/handoff/08_Analytics_Events.md').readAsStringSync();
  final table = doc.substring(
    doc.indexOf('## Event table'),
    doc.indexOf('## Marberx-wide standard names'),
  );
  final names = <String>{};
  for (final line in table.split('\n')) {
    if (!line.startsWith('| `')) continue;
    final first = line.split('|')[1];
    names.addAll(
      RegExp(r'`([a-z_]+)`').allMatches(first).map((m) => m.group(1)!),
    );
  }
  return names;
}

final _personal = RegExp(r'\.(mp3|m4a|m4r|mov|mp4|wav|flac)\b|/|@');

void _expectNoPersonalData(FakeAnalytics analytics) {
  for (final (name, props) in analytics.events) {
    for (final value in props.values.whereType<String>()) {
      expect(_personal.hasMatch(value), isFalse, reason: '$name: $value');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Event helpers', () {
    for (final (name, keys, call) in _cases) {
      test('$name sends exactly ${keys.isEmpty ? 'no properties' : keys}', () {
        final analytics = FakeAnalytics();
        call(analytics);
        expect(analytics.events, hasLength(1));
        expect(analytics.events.single.$1, name);
        expect(analytics.events.single.$2.keys.toSet(), keys);
      });
    }

    test('one helper per event in 08 (and nothing extra)', () {
      final covered = {for (final c in _cases) c.$1};
      expect(covered, _specEvents());
    });

    test('names follow object_action snake_case', () {
      for (final c in _cases) {
        expect(RegExp(r'^[a-z]+(_[a-z0-9]+)+$').hasMatch(c.$1), isTrue);
      }
    });

    test('sizes and durations are rounded to one decimal', () {
      expect(mb(1363148), 1.3);
      expect(secs(2.649), 2.6);
    });
  });

  group('Values', () {
    test('goal, frequency, tone and plan names as in 08', () {
      expect(AnalyticsValues.goal(UserGoal.mp3FromVideos), 'mp3');
      expect(AnalyticsValues.frequency(UsageFrequency.onceInAWhile), 'rarely');
      expect(AnalyticsValues.toneType(ToneType.textTone), 'text');
      expect(AnalyticsValues.plan(Entitlement.free), 'none');
      expect(
        AnalyticsValues.plan(
          const Entitlement(isPro: true, isTrial: true, productId: 'x.yearly'),
        ),
        'trial',
      );
      expect(
        AnalyticsValues.plan(
          const Entitlement(isPro: true, productId: 'tunely.pro.yearly.exit'),
        ),
        'yearly_exit',
      );
      expect(
        AnalyticsValues.plan(
          const Entitlement(isPro: true, productId: 'tunely.pro.yearly'),
          lastKind: PlanKind.winBack,
        ),
        'yearly_winback',
      );
      expect(
        AnalyticsValues.plan(
          const Entitlement(isPro: true, productId: 'tunely.pro.lifetime'),
        ),
        'lifetime',
      );
    });

    test('error codes map to error_type and error screen type', () {
      expect(AnalyticsValues.errorType(EngineErrorCode.noSpace), 'io');
      expect(
        AnalyticsValues.errorScreen(EngineErrorCode.noSpace),
        'no_storage',
      );
      expect(AnalyticsValues.errorScreen(EngineErrorCode.protected), 'drm');
    });
  });

  group('Wiring', () {
    late FakeEngine engine;
    setUp(() => engine = FakeEngine(Directory.systemTemp.createTempSync('an')));

    SourceFile source(String name) => SourceFile(
      path: '/tmp/$name',
      name: name,
      info: fakeInfo(path: '/tmp/$name'),
    );

    test(
      'a conversion sends task_started then task_completed with free_left',
      () async {
        final analytics = FakeAnalytics();
        final container = testContainer(engine: engine, analytics: analytics);
        addTearDown(container.dispose);
        container
            .read(draftProvider.notifier)
            .start(source('Dance_night.mov'), mode: ConvertMode.audioFile);
        await container
            .read(jobProvider.notifier)
            .start(container.read(draftProvider)!);

        expect(analytics.names.where((n) => n.startsWith('task_')), [
          Events.taskStarted,
          Events.taskCompleted,
        ]);
        final done = analytics.last(Events.taskCompleted);
        expect(done['task'], 'convert');
        expect(
          done['free_left'],
          container.read(freeLimitProvider.notifier).remaining,
        );
        _expectNoPersonalData(analytics);
      },
    );

    test(
      'a ringtone also sends ringtone_created; a failure task_failed',
      () async {
        final analytics = FakeAnalytics();
        final container = testContainer(engine: engine, analytics: analytics);
        addTearDown(container.dispose);
        final drafts = container.read(draftProvider.notifier)
          ..start(source('Song.mov'), mode: ConvertMode.ringtone);
        await container
            .read(jobProvider.notifier)
            .start(container.read(draftProvider)!);
        expect(analytics.names, contains(Events.ringtoneCreated));
        expect(analytics.last(Events.ringtoneCreated)['tone_type'], 'ringtone');

        engine.failWith = EngineErrorCode.decode;
        drafts.start(source('Bad.mov'), mode: ConvertMode.audioFile);
        await container
            .read(jobProvider.notifier)
            .start(container.read(draftProvider)!);
        expect(analytics.last(Events.taskFailed)['error_type'], 'decode');
        _expectNoPersonalData(analytics);
      },
    );

    test('a batch sends batch_started and batch_completed once', () async {
      final analytics = FakeAnalytics();
      final container = testContainer(engine: engine, analytics: analytics);
      addTearDown(container.dispose);
      engine.failPaths.add('/tmp/b.mov');
      await container.read(batchProvider.notifier).start(
        [source('a.mov'), source('b.mov')],
        BatchCopy(
          backgroundTitle: 't',
          progress: (d, t) => '$d/$t',
          doneTitle: 'd',
          doneBody: (n) => '$n',
        ),
      );
      for (var i = 0; i < 50 && container.read(batchProvider)!.running; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(
        analytics.names.where((n) => n == Events.batchStarted),
        hasLength(1),
      );
      expect(
        analytics.last(Events.batchCompleted),
        containsPair('failed_count', 1),
      );
      _expectNoPersonalData(analytics);
    });

    test(
      'super and user properties are set at start and follow purchases',
      () async {
        final analytics = FakeAnalytics();
        final purchases = DemoPurchasesService();
        final container = testContainer(
          engine: engine,
          analytics: analytics,
          purchases: purchases,
        );
        addTearDown(container.dispose);
        await container.read(analyticsSyncProvider).start();

        expect(analytics.distinctId, isNotNull);
        for (final key in [
          'app_version',
          'ios_version',
          'is_pro',
          'plan',
          'goal',
          'frequency',
          'theme',
          'session_number',
        ]) {
          expect(analytics.superProps.containsKey(key), isTrue, reason: key);
        }
        for (final key in [
          'goal',
          'frequency',
          'is_pro',
          'plan',
          'first_open_date',
          'files_made_total',
          'ringtones_made_total',
          'notifications_enabled',
          'ios_major',
        ]) {
          expect(analytics.userProps.containsKey(key), isTrue, reason: key);
        }
        expect(analytics.superProps['is_pro'], isFalse);

        await purchases.purchase(
          (await purchases.plans(OfferingId.main)).first,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(analytics.superProps['is_pro'], isTrue);
        expect(analytics.superProps['plan'], 'trial');
      },
    );
  });
}
