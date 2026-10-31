import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/ads_service.dart';
import '../core/analytics/analytics.dart';
import '../core/library/usage_store.dart';
import '../core/rules/ad_policy.dart';
import '../core/rules/free_limit.dart';
import 'config.dart';
import 'monetization.dart';
import 'state.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  final config = ref.watch(appConfigProvider).ads;
  if (!config.enabled) return const NoAdsService();
  if (config.provider == 'levelplay') return const LevelPlayAdsService();
  final units = kReleaseMode ? AdUnits.fromEnvironment() : AdUnits.test;
  if (units == null) return const NoAdsService();
  return AdMobAdsService(units, ref.watch(analyticsProvider));
});

class AdsState {
  const AdsState({
    this.memory = const AdMemory(),
    this.started = false,
    this.adBreakThisSession = false,
  });

  final AdMemory memory;

  /// Consent resolved and the SDK started; ads may be requested.
  final bool started;

  /// The house card never shares a session with an ad break (`05` §13).
  final bool adBreakThisSession;

  AdsState copyWith({
    AdMemory? memory,
    bool? started,
    bool? adBreakThisSession,
  }) {
    return AdsState(
      memory: memory ?? this.memory,
      started: started ?? this.started,
      adBreakThisSession: adBreakThisSession ?? this.adBreakThisSession,
    );
  }
}

/// Applies `AdPolicy` with real state. Pro users never get ads.
class AdsController extends Notifier<AdsState> {
  Future<void>? _starting;

  @override
  AdsState build() {
    unawaited(_loadMemory());
    return const AdsState();
  }

  AdsService get _service => ref.read(adsServiceProvider);
  bool get _isPro => ref.read(isProProvider);

  Future<void> _loadMemory() async {
    final memory = await ref.read(usageStoreProvider).adMemory();
    if (ref.mounted) state = state.copyWith(memory: memory);
  }

  Future<void> _save(AdMemory memory) async {
    state = state.copyWith(memory: memory);
    await ref.read(usageStoreProvider).writeAdMemory(memory);
  }

  /// UMP consent (form only where required), then the SDK. Free users only.
  Future<void> start() {
    if (_isPro || state.started) return Future.value();
    return _starting ??= () async {
      final ok = await _service.init();
      if (ref.mounted) state = state.copyWith(started: ok);
      _starting = null;
    }();
  }

  /// A successful single conversion (not merge or batch).
  Future<void> noteConversion() async {
    await _loadMemory();
    await _save(AdPolicy.afterConversion(state.memory));
  }

  bool canAdBreak({
    bool afterErrorInFlow = false,
    bool paywallInFlow = false,
    bool houseCardOnScreen = false,
    int? lifetimeConversions,
    DateTime? now,
  }) {
    final config = ref.read(appConfigProvider).ads;
    return AdPolicy.canShowAdBreak(
      AdBreakRequest(
        memory: state.memory,
        now: now ?? DateTime.now(),
        isPro: _isPro,
        adsEnabled: config.enabled && state.started,
        firstSession: ref.read(paywallProvider).memory.sessions <= 1,
        lifetimeConversions: lifetimeConversions ?? 0,
        afterErrorInFlow: afterErrorInFlow,
        paywallInFlow: paywallInFlow,
        houseCardOnScreen: houseCardOnScreen,
        firstSessionAds: config.firstSessionAds,
        minConversionsBeforeFirstAd: config.minConversionsBeforeFirstAd,
        everyNthConversion: config.everyNthConversion,
        minSecondsBetween: config.minSecondsBetween,
        maxPerDay: config.maxPerDay,
      ),
    );
  }

  bool isReady(AdFormat format) => _service.isReady(format);

  Future<void> preload(AdFormat format) async {
    if (_isPro || !state.started) return;
    await _service.load(format);
  }

  /// Shows the interstitial after the user tapped Continue on 42.
  Future<bool> showAdBreak() async {
    final shown = await _service.showInterstitial();
    if (shown) {
      state = state.copyWith(adBreakThisSession: true);
      await _save(AdPolicy.afterAdBreak(state.memory, DateTime.now()));
    }
    return shown;
  }

  bool canOfferRewarded() {
    final config = ref.read(appConfigProvider).ads;
    return state.started &&
        _service.isReady(AdFormat.rewarded) &&
        AdPolicy.canOfferRewarded(
          memory: state.memory,
          now: DateTime.now(),
          isPro: _isPro,
          adsEnabled: config.enabled,
          rewardedMaxPerDay: config.rewardedMaxPerDay,
        );
  }

  /// +1 free conversion only from the SDK reward callback. Returns whether
  /// the reward was earned.
  Future<bool> watchRewarded() async {
    var earned = false;
    await _service.showRewarded(
      onReward: () {
        earned = true;
        unawaited(_reward());
      },
    );
    return earned;
  }

  Future<void> _reward() async {
    await ref.read(freeLimitProvider.notifier).addRewarded();
    await _save(AdPolicy.afterReward(state.memory, DateTime.now()));
  }

  int rewardedToday() =>
      state.memory.rewardedOn(FreeLimit.dayKeyFor(DateTime.now()));
}

final adsProvider = NotifierProvider<AdsController, AdsState>(
  AdsController.new,
);
