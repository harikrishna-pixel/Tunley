import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/config.dart';
import 'package:tunely/core/rules/free_limit.dart';
import 'package:tunely/core/rules/paywall_triggers.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/core/rules/preflight.dart';
import 'package:tunely/core/rules/rating_rules.dart';
import 'package:tunely/core/rules/ringtone_rules.dart';
import 'package:tunely/core/rules/size_estimator.dart';

void main() {
  late AppConfig config;

  setUpAll(() async {
    final json = jsonDecode(
      await File('assets/config/app_config.json').readAsString(),
    ) as Map<String, dynamic>;
    config = AppConfig.fromJson(json);
  });

  group('preflight', () {
    test('stops at the first failure', () {
      final outcome = Preflight.check(
        PreflightInput(
          canOpen: false,
          hasAudioTrack: false,
          hasProtectedContent: true,
          icloudDownloadFailed: true,
          freeBytes: 0,
          estimateBytes: 1000,
          isPro: false,
          requestsProFeature: true,
          usedToday: 9,
          rewardedToday: 0,
          config: config,
        ),
      );

      expect(outcome.block, PreflightBlock.unreadable);
    });

    test('no audio track is E4, after a file that opens', () {
      final outcome = Preflight.check(
        _input(config).copyWith(canOpen: true, hasAudioTrack: false),
      );
      expect(outcome.block, PreflightBlock.noAudio);
    });

    test('protected content is E4 after a readable audio file', () {
      final outcome = Preflight.check(
        _input(config).copyWith(hasProtectedContent: true),
      );
      expect(outcome.block, PreflightBlock.protected);
    });

    test('iCloud download failure is E3', () {
      final outcome = Preflight.check(
        _input(config).copyWith(icloudDownloadFailed: true),
      );
      expect(outcome.block, PreflightBlock.icloud);
    });

    test('missing space reports how many MB are short', () {
      const mb = 1024 * 1024;
      final outcome = Preflight.check(
        _input(config).copyWith(estimateBytes: 10 * mb, freeBytes: 60 * mb),
      );
      expect(outcome.block, PreflightBlock.noSpace);
      expect(outcome.missingMb, 10);
    });

    test('pro gate comes before the free limit and does not count', () {
      final outcome = Preflight.check(
        _input(config).copyWith(requestsProFeature: true, usedToday: 3),
      );
      expect(outcome.block, PreflightBlock.proFeature);
      expect(outcome.countsConversion, isFalse);
    });

    test('fourth conversion of the day is the free-limit gate', () {
      final outcome = Preflight.check(_input(config).copyWith(usedToday: 3));
      expect(outcome.block, PreflightBlock.freeLimit);
      expect(outcome.countsConversion, isFalse);
    });

    test('a rewarded conversion extends the daily allowance', () {
      final outcome = Preflight.check(
        _input(config).copyWith(usedToday: 3, rewardedToday: 1),
      );
      expect(outcome.allowed, isTrue);
    });

    test('pro formats, tones, boost, merge, and batches are the pro gate', () {
      expect(ProGate.requires(format: OutputFormat.flac), isTrue);
      expect(ProGate.requires(format: OutputFormat.aac), isTrue);
      expect(ProGate.requires(format: OutputFormat.ogg), isTrue);
      expect(ProGate.requires(format: OutputFormat.mp3), isFalse);
      expect(ProGate.requires(format: OutputFormat.m4a), isFalse);
      expect(ProGate.requires(tone: ToneType.alarm), isTrue);
      expect(ProGate.requires(tone: ToneType.textTone), isTrue);
      expect(ProGate.requires(tone: ToneType.ringtone), isFalse);
      expect(ProGate.requires(volumeBoost: true), isTrue);
      expect(ProGate.requires(merge: true), isTrue);
      expect(ProGate.requires(fileCount: 2), isTrue);
      expect(ProGate.requires(fileCount: 1), isFalse);
    });

    test('pro users skip the pro gate and the free limit', () {
      final outcome = Preflight.check(
        _input(config)
            .copyWith(isPro: true, requestsProFeature: true, usedToday: 20),
      );
      expect(outcome.allowed, isTrue);
    });
  });

  group('free limit', () {
    test('resets at the next local midnight', () {
      final used = FreeLimitSnapshot(
        usedToday: 3,
        rewardedToday: 1,
        dayKey: '2026-10-29',
        maxDayKey: '2026-10-29',
      );
      final next = FreeLimit.reconcile(used, DateTime(2026, 10, 30, 0, 5));
      expect(next.usedToday, 0);
      expect(next.rewardedToday, 0);
      expect(next.dayKey, '2026-10-30');
    });

    test('clock turned back does not grant extra uses', () {
      final used = FreeLimitSnapshot(
        usedToday: 3,
        rewardedToday: 0,
        dayKey: '2026-10-29',
        maxDayKey: '2026-10-29',
      );
      final rolled = FreeLimit.reconcile(used, DateTime(2026, 10, 28, 9));
      expect(rolled.usedToday, 3);
      expect(rolled.dayKey, '2026-10-29');
      expect(
        FreeLimit.isAtLimit(rolled, freePerDay: config.freeConversionsPerDay),
        isTrue,
      );
    });

    test('cancelled or failed jobs do not count', () {
      const start = FreeLimitSnapshot(
        usedToday: 1,
        rewardedToday: 0,
        dayKey: '2026-10-29',
        maxDayKey: '2026-10-29',
      );
      expect(
        FreeLimit.recordFinished(
          start,
          success: false,
          outputExists: false,
          isNewConversion: true,
        ).usedToday,
        1,
      );
      expect(
        FreeLimit.recordFinished(
          start,
          success: false,
          outputExists: true,
          isNewConversion: true,
        ).usedToday,
        1,
      );
      expect(
        FreeLimit.recordFinished(
          start,
          success: true,
          outputExists: false,
          isNewConversion: true,
        ).usedToday,
        1,
      );
      expect(
        FreeLimit.recordFinished(
          start,
          success: true,
          outputExists: true,
          isNewConversion: false,
        ).usedToday,
        1,
      );
    });

    test('a successful new file counts once', () {
      const start = FreeLimitSnapshot(
        usedToday: 1,
        rewardedToday: 0,
        dayKey: '2026-10-29',
        maxDayKey: '2026-10-29',
      );
      final next = FreeLimit.recordFinished(
        start,
        success: true,
        outputExists: true,
        isNewConversion: true,
      );
      expect(next.usedToday, 2);
    });
  });

  group('size estimator', () {
    test('42 seconds at 256 kbps is about 1.3 MB', () {
      final estimate = SizeEstimator.estimate(
        preset: AudioPreset.high,
        seconds: 42,
      );
      expect(estimate.label, '~1.3 MB');
    });

    test('30 second ringtone is about 0.5 MB', () {
      final estimate = SizeEstimator.estimate(
        preset: AudioPreset.ringtone,
        seconds: 30,
      );
      expect(estimate.label, '~0.5 MB');
    });

    test('WAV and FLAC follow the sample formula', () {
      final wav = SizeEstimator.estimate(preset: AudioPreset.wav, seconds: 10);
      expect(wav.bytes, 44100 * 2 * 2 * 10);
      final flac = SizeEstimator.estimate(
        preset: AudioPreset.flac,
        seconds: 10,
      );
      expect(flac.bytes, (wav.bytes * 0.55).round());
      expect(flac.approximate, isTrue);
    });

    test('a lower source bitrate adds the caption', () {
      final estimate = SizeEstimator.estimate(
        preset: AudioPreset.high,
        seconds: 42,
        sourceBitrateKbps: 128,
      );
      expect(
        estimate.sourceCaption,
        'Source is 128 kbps. Higher won\'t improve it.',
      );
    });

    test('sizes of 10 MB and up are whole numbers', () {
      final estimate = SizeEstimator.estimate(
        preset: AudioPreset.high,
        seconds: 400,
      );
      expect(estimate.label, matches(RegExp(r'^~\d+ MB$')));
    });
  });

  group('paywall triggers', () {
    test('exit offer is shown only once ever', () {
      final first = PaywallTriggers.canShow(
        _paywall(trigger: PaywallTrigger.p6, closingP1: true),
      );
      expect(first, isTrue);
      final again = PaywallTriggers.canShow(
        _paywall(
          trigger: PaywallTrigger.p6,
          closingP1: true,
          exitOfferEverShown: true,
        ),
      );
      expect(again, isFalse);
    });

    test('two paywalls in a row are blocked, except P1 close to P6', () {
      expect(
        PaywallTriggers.canShow(
          _paywall(trigger: PaywallTrigger.p4, previousWasPaywall: true),
        ),
        isFalse,
      );
      expect(
        PaywallTriggers.canShow(
          _paywall(
            trigger: PaywallTrigger.p6,
            previousWasPaywall: true,
            closingP1: true,
          ),
        ),
        isTrue,
      );
    });

    test('a second unrequested paywall in the session is blocked', () {
      expect(
        PaywallTriggers.canShow(
          _paywall(trigger: PaywallTrigger.p5, unrequestedThisSession: 1),
        ),
        isFalse,
      );
      expect(
        PaywallTriggers.canShow(
          _paywall(trigger: PaywallTrigger.p2, unrequestedThisSession: 1),
        ),
        isTrue,
      );
    });

    test('pro users do not see P1–P6 or P8', () {
      for (final trigger in [
        PaywallTrigger.p1,
        PaywallTrigger.p2,
        PaywallTrigger.p3,
        PaywallTrigger.p4,
        PaywallTrigger.p5,
        PaywallTrigger.p6,
        PaywallTrigger.p8,
      ]) {
        expect(
          PaywallTriggers.canShow(_paywall(trigger: trigger, isPro: true)),
          isFalse,
          reason: trigger.name,
        );
      }
    });

    test('P4 is once a day, and once every 3 sessions when occasional', () {
      expect(
        PaywallTriggers.canShow(
          _paywall(trigger: PaywallTrigger.p4, conversionsToday: 3),
        ),
        isTrue,
      );
      expect(
        PaywallTriggers.canShow(
          _paywall(
            trigger: PaywallTrigger.p4,
            conversionsToday: 3,
            p4ShownToday: true,
          ),
        ),
        isFalse,
      );
      expect(
        PaywallTriggers.canShow(
          _paywall(
            trigger: PaywallTrigger.p4,
            conversionsToday: 3,
            frequency: UsageFrequency.onceInAWhile,
            sessionsSinceP4: 2,
          ),
        ),
        isFalse,
      );
      expect(
        PaywallTriggers.canShow(
          _paywall(
            trigger: PaywallTrigger.p4,
            conversionsToday: 3,
            frequency: UsageFrequency.onceInAWhile,
            sessionsSinceP4: 3,
          ),
        ),
        isTrue,
      );
    });

    test(
      'paywalls stay hidden while busy, after an error, or in questions',
      () {
        expect(
          PaywallTriggers.canShow(
            _paywall(trigger: PaywallTrigger.p2, busy: true),
          ),
          isFalse,
        );
        expect(
          PaywallTriggers.canShow(
            _paywall(trigger: PaywallTrigger.p3, afterError: true),
          ),
          isFalse,
        );
        expect(
          PaywallTriggers.canShow(
            _paywall(
              trigger: PaywallTrigger.p1,
              duringOnboardingQuestions: true,
            ),
          ),
          isFalse,
        );
      },
    );
  });

  group('personalization', () {
    test('maps onboarding answers to convert mode, picker, and plans', () {
      final ringtones = Personalization(
        goal: UserGoal.ringtones,
        frequency: UsageFrequency.fewTimesAWeek,
      );
      expect(ringtones.convertMode, ConvertMode.ringtone);
      expect(ringtones.emphasiseYearly, isFalse);

      final mp3 = Personalization(
        goal: UserGoal.mp3FromVideos,
        frequency: UsageFrequency.everyDay,
      );
      expect(mp3.convertMode, ConvertMode.audioFile);
      expect(mp3.picker, PickerSource.videos);
      expect(mp3.defaultPreset, AudioPreset.high);
      expect(mp3.emphasiseYearly, isTrue);

      final convert = Personalization(
        goal: UserGoal.convertFiles,
        frequency: UsageFrequency.onceInAWhile,
      );
      expect(convert.picker, PickerSource.audioFiles);
      expect(convert.defaultPreset, isNull);
      expect(convert.lifetimeListedSecond, isTrue);
      expect(convert.p4EveryThreeSessions, isTrue);
    });
  });

  group('rating', () {
    test('asks after the 2nd ringtone or the 5th conversion', () {
      expect(
        RatingRules.shouldAsk(
          _rating(ringtonesSaved: 2, successfulConversions: 0),
        ),
        isTrue,
      );
      expect(
        RatingRules.shouldAsk(
          _rating(ringtonesSaved: 0, successfulConversions: 5),
        ),
        isTrue,
      );
      expect(
        RatingRules.shouldAsk(
          _rating(ringtonesSaved: 1, successfulConversions: 4),
        ),
        isFalse,
      );
    });

    test('caps repeats and skips a session with an error or a paywall', () {
      expect(
        RatingRules.shouldAsk(_rating(ringtonesSaved: 2, timesAsked: 2)),
        isFalse,
      );
      expect(
        RatingRules.shouldAsk(
          _rating(
            ringtonesSaved: 2,
            timesAsked: 1,
            lastAskedAt: DateTime(2026, 10, 20),
            now: DateTime(2026, 10, 29),
          ),
        ),
        isFalse,
      );
      expect(
        RatingRules.shouldAsk(
          _rating(ringtonesSaved: 2, errorThisSession: true),
        ),
        isFalse,
      );
      expect(
        RatingRules.shouldAsk(
          _rating(ringtonesSaved: 2, paywallThisSession: true),
        ),
        isFalse,
      );
    });
  });

  group('ringtone rules', () {
    test('default selection is the loudest 30 seconds', () {
      final peaks = List<double>.filled(60, 0.1);
      for (var i = 40; i <= 50; i++) {
        peaks[i] = 1;
      }
      final selection = RingtoneRules.defaultSelection(
        duration: const Duration(seconds: 60),
        peaks: peaks,
        type: ToneType.ringtone,
        config: config,
      );
      expect(selection.duration.inSeconds, 30);
      expect(selection.start.inSeconds, lessThanOrEqualTo(40));
      expect(selection.end.inSeconds, greaterThanOrEqualTo(50));
    });

    test('short files use the whole clip', () {
      final selection = RingtoneRules.defaultSelection(
        duration: const Duration(seconds: 12),
        peaks: const [0.2, 0.9, 0.2],
        type: ToneType.ringtone,
        config: config,
      );
      expect(selection.start, Duration.zero);
      expect(selection.end, const Duration(seconds: 12));
    });

    test('text tones default to 5 seconds and alarm is pro', () {
      final peaks = List<double>.filled(60, 0.1);
      peaks[42] = 1;
      final selection = RingtoneRules.defaultSelection(
        duration: const Duration(seconds: 60),
        peaks: peaks,
        type: ToneType.textTone,
        config: config,
      );
      expect(selection.duration.inSeconds, 5);
      expect(selection.start.inSeconds, lessThanOrEqualTo(42));
      expect(selection.end.inSeconds, greaterThanOrEqualTo(42));
      expect(RingtoneRules.isPro(ToneType.ringtone), isFalse);
      expect(RingtoneRules.isPro(ToneType.alarm), isTrue);
      expect(RingtoneRules.isPro(ToneType.textTone), isTrue);
    });

    test('fades snap to half seconds inside 0–5', () {
      expect(
        RingtoneRules.snapFade(2.3, maxSeconds: config.fadeMaxSeconds),
        2.5,
      );
      expect(RingtoneRules.snapFade(-1, maxSeconds: config.fadeMaxSeconds), 0);
      expect(RingtoneRules.snapFade(9, maxSeconds: config.fadeMaxSeconds), 5);
      expect(config.fadeDefaultSeconds, 2);
    });

    test('file name uses the source and the m4r suffix', () {
      expect(RingtoneRules.fileName('Interview.mov'), 'Interview_tone.m4r');
    });
  });
}

PreflightInput _input(AppConfig config) {
  return PreflightInput(
    canOpen: true,
    hasAudioTrack: true,
    hasProtectedContent: false,
    icloudDownloadFailed: false,
    freeBytes: 500 * 1024 * 1024,
    estimateBytes: 2 * 1024 * 1024,
    isPro: false,
    requestsProFeature: false,
    usedToday: 0,
    rewardedToday: 0,
    config: config,
  );
}

PaywallContext _paywall({
  required PaywallTrigger trigger,
  bool isPro = false,
  bool busy = false,
  bool afterError = false,
  bool duringOnboardingQuestions = false,
  int unrequestedThisSession = 0,
  bool previousWasPaywall = false,
  bool closingP1 = false,
  UsageFrequency frequency = UsageFrequency.fewTimesAWeek,
  int conversionsToday = 3,
  bool p4ShownToday = false,
  int sessionsSinceP4 = 99,
  bool exitOfferEverShown = false,
}) {
  return PaywallContext(
    trigger: trigger,
    isPro: isPro,
    busy: busy,
    afterError: afterError,
    duringOnboardingQuestions: duringOnboardingQuestions,
    unrequestedThisSession: unrequestedThisSession,
    maxUnrequestedPerSession: 1,
    previousWasPaywall: previousWasPaywall,
    closingP1: closingP1,
    frequency: frequency,
    p1AlreadyShown: false,
    conversionsToday: conversionsToday,
    p4ShownToday: p4ShownToday,
    sessionsSinceP4: sessionsSinceP4,
    lifetimeFiles: 10,
    heavyUserFiles: 10,
    p5AlreadyShown: false,
    exitOfferEverShown: exitOfferEverShown,
    inTrial: false,
    trialDay2: false,
    p7AlreadyShown: false,
    lapsedAt: DateTime(2026, 9, 1),
    lastWinBackAt: null,
    now: DateTime(2026, 10, 29),
    winBackAfterDays: 14,
    winBackCooldownDays: 90,
  );
}

RatingRequest _rating({
  int ringtonesSaved = 0,
  int successfulConversions = 0,
  int timesAsked = 0,
  DateTime? lastAskedAt,
  DateTime? now,
  bool errorThisSession = false,
  bool paywallThisSession = false,
}) {
  return RatingRequest(
    ringtonesSaved: ringtonesSaved,
    successfulConversions: successfulConversions,
    timesAsked: timesAsked,
    lastAskedAt: lastAskedAt,
    now: now ?? DateTime(2026, 10, 29),
    errorThisSession: errorThisSession,
    paywallThisSession: paywallThisSession,
    afterRingtones: 2,
    afterConversions: 5,
    maxTimes: 2,
    minDaysBetween: 30,
  );
}
