import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../analytics/analytics.dart';
import '../analytics/events.dart';

enum AdFormat { interstitial, rewarded }

/// Every ad goes through this (`05` §12 / `17`). Implementations never draw
/// our UI over a network ad and fail silently on no fill or offline.
abstract class AdsService {
  String get provider;

  /// Consent / privacy flags, then SDK start. Returns whether ads may be
  /// requested.
  Future<bool> init();

  Future<void> load(AdFormat format);
  bool isReady(AdFormat format);

  /// Shows a loaded interstitial; completes when it is closed (or at once when
  /// nothing is loaded). Returns whether an ad was shown.
  Future<bool> showInterstitial();

  /// Shows a loaded rewarded ad; [onReward] runs only from the SDK callback.
  Future<bool> showRewarded({required VoidCallback onReward});
}

/// Pro users, release builds without unit IDs, `ads.enabled = false`.
class NoAdsService implements AdsService {
  const NoAdsService();

  @override
  String get provider => 'none';

  @override
  Future<bool> init() async => false;

  @override
  Future<void> load(AdFormat format) async {}

  @override
  bool isReady(AdFormat format) => false;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<bool> showRewarded({required VoidCallback onReward}) async => false;
}

class AdUnits {
  const AdUnits({required this.interstitial, required this.rewarded});

  final String interstitial;
  final String rewarded;

  /// Google's public iOS test units (debug / TestFlight).
  static const test = AdUnits(
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  /// Production units from `--dart-define`; null when not provided.
  static AdUnits? fromEnvironment() {
    const interstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
    const rewarded = String.fromEnvironment('ADMOB_REWARDED_IOS');
    if (interstitial.isEmpty || rewarded.isEmpty) return null;
    return const AdUnits(interstitial: interstitial, rewarded: rewarded);
  }
}

/// Google AdMob (with mediation adapters added in the iOS project).
///
/// Unused this version — `ads.provider` is `levelplay`. Kept so we can switch
/// back without rewriting the AdMob path.
class AdMobAdsService implements AdsService {
  AdMobAdsService(this._units, this._analytics);

  final AdUnits _units;
  final Analytics _analytics;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _started = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  @override
  String get provider => 'admob';

  @override
  Future<bool> init() async {
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        _analytics.consentResult(status: status.name);
        if (!consent.isCompleted) consent.complete();
      }),
      (_) {
        if (!consent.isCompleted) consent.complete();
      },
    );
    await consent.future;
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    if (!_started) {
      await MobileAds.instance.initialize();
      _started = true;
    }
    return true;
  }

  @override
  bool isReady(AdFormat format) => switch (format) {
    AdFormat.interstitial => _interstitial != null,
    AdFormat.rewarded => _rewarded != null,
  };

  @override
  Future<void> load(AdFormat format) async {
    if (!_started || isReady(format)) return;
    _analytics.adRequested(format: format.name, provider: provider);
    switch (format) {
      case AdFormat.interstitial:
        if (_loadingInterstitial) return;
        _loadingInterstitial = true;
        await InterstitialAd.load(
          adUnitId: _units.interstitial,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _loadingInterstitial = false;
              _interstitial = ad;
              _analytics.adLoaded(format: format.name, provider: provider);
            },
            onAdFailedToLoad: (error) {
              _loadingInterstitial = false;
              _failed(format, error);
            },
          ),
        );
      case AdFormat.rewarded:
        if (_loadingRewarded) return;
        _loadingRewarded = true;
        await RewardedAd.load(
          adUnitId: _units.rewarded,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _loadingRewarded = false;
              _rewarded = ad;
              _analytics.adLoaded(format: format.name, provider: provider);
            },
            onAdFailedToLoad: (error) {
              _loadingRewarded = false;
              _failed(format, error);
            },
          ),
        );
    }
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = _callbacks<InterstitialAd>(
      AdFormat.interstitial,
      closed,
    );
    await ad.show();
    return closed.future;
  }

  @override
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = _callbacks<RewardedAd>(
      AdFormat.rewarded,
      closed,
    );
    await ad.show(onUserEarnedReward: (_, _) => onReward());
    return closed.future;
  }

  FullScreenContentCallback<T> _callbacks<T extends Ad>(
    AdFormat format,
    Completer<bool> closed,
  ) {
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (ad) => _analytics.adShown(
        format: format.name,
        provider: provider,
        network: ad.responseInfo?.mediationAdapterClassName,
      ),
      onAdClicked: (_) =>
          _analytics.adClicked(format: format.name, provider: provider),
      onAdDismissedFullScreenContent: (ad) {
        _analytics.adClosed(format: format.name, provider: provider);
        ad.dispose();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _analytics.adFailed(
          format: format.name,
          provider: provider,
          reason: 'error',
        );
        ad.dispose();
        if (!closed.isCompleted) closed.complete(false);
      },
    );
  }

  void _failed(AdFormat format, LoadAdError error) {
    // AdMob: 3 = no fill, 2 = network error.
    final reason = switch (error.code) {
      3 => 'no_fill',
      2 => 'offline',
      _ => 'error',
    };
    _analytics.adFailed(
      format: format.name,
      provider: provider,
      reason: reason,
    );
  }
}

/// ironSource / Unity LevelPlay (`17`). Interstitial + rewarded only.
class LevelPlayUnits {
  const LevelPlayUnits({
    required this.appKey,
    required this.interstitial,
    required this.rewarded,
  });

  final String appKey;
  final String interstitial;
  final String rewarded;

  /// Tunely (dashboard: Audio Converter) production IDs.
  static const production = LevelPlayUnits(
    appKey: '2985a82b5',
    interstitial: 't4n509uk215g88ju',
    rewarded: 'w88wxfv9286yj7ih',
  );

  /// Override with `--dart-define=LEVELPLAY_*`; falls back to [production].
  static LevelPlayUnits fromEnvironment() {
    const appKey = String.fromEnvironment(
      'LEVELPLAY_APP_KEY',
      defaultValue: '2985a82b5',
    );
    const interstitial = String.fromEnvironment(
      'LEVELPLAY_INTERSTITIAL_IOS',
      defaultValue: 't4n509uk215g88ju',
    );
    const rewarded = String.fromEnvironment(
      'LEVELPLAY_REWARDED_IOS',
      defaultValue: 'w88wxfv9286yj7ih',
    );
    if (appKey.isEmpty || interstitial.isEmpty || rewarded.isEmpty) {
      return production;
    }
    return const LevelPlayUnits(
      appKey: appKey,
      interstitial: interstitial,
      rewarded: rewarded,
    );
  }
}

class LevelPlayAdsService implements AdsService {
  LevelPlayAdsService(this._units, this._analytics);

  final LevelPlayUnits _units;
  final Analytics _analytics;

  /// Placement names from `17` §1 (dashboard capping/pacing).
  static const interstitialPlacement = 'after_task_interstitial';
  static const rewardedPlacement = 'daily_limit_rewarded';

  LevelPlayInterstitialAd? _interstitial;
  LevelPlayRewardedAd? _rewarded;
  bool _started = false;
  bool _interstitialReady = false;
  bool _rewardedReady = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  VoidCallback? _onReward;
  Completer<bool>? _interstitialClosed;
  Completer<bool>? _rewardedClosed;

  @override
  String get provider => 'levelplay';

  @override
  Future<bool> init() async {
    if (_started) return true;

    // UMP where required (EEA/UK/CH), then pass the result to LevelPlay so it
    // forwards GDPR/CCPA to mediated networks (doc 17 / Google↔ironSource).
    await _applyUmConsentToLevelPlay();

    if (kDebugMode) {
      await LevelPlay.setMetaData({
        'is_test_suite': ['enable'],
      });
      await LevelPlay.setAdaptersDebug(true);
    }

    final done = Completer<bool>();
    final request = LevelPlayInitRequest.builder(_units.appKey).build();
    await LevelPlay.init(
      initRequest: request,
      initListener: _LevelPlayInitListener(
        onSuccess: () {
          if (!done.isCompleted) done.complete(true);
        },
        onFailed: () {
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    final ok = await done.future;
    _started = ok;
    return ok;
  }

  /// Google UMP form if required, then LevelPlay privacy APIs (before init).
  Future<void> _applyUmConsentToLevelPlay() async {
    final ump = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        _analytics.consentResult(status: status.name);
        if (!ump.isCompleted) ump.complete();
      }),
      (_) {
        if (!ump.isCompleted) ump.complete();
      },
    );
    await ump.future;

    final consented = await ConsentInformation.instance.canRequestAds();
    // Doc 17: not child-directed.
    await LevelPlayPrivacySettings.setCOPPA(false);
    await LevelPlayPrivacySettings.setGDPRConsent(consented);
    // No separate "do not sell" signal from UMP here; default not opted out.
    await LevelPlayPrivacySettings.setCCPA(false);
  }

  @override
  bool isReady(AdFormat format) => switch (format) {
    AdFormat.interstitial => _interstitialReady,
    AdFormat.rewarded => _rewardedReady,
  };

  @override
  Future<void> load(AdFormat format) async {
    if (!_started || isReady(format)) return;
    _analytics.adRequested(format: format.name, provider: provider);
    switch (format) {
      case AdFormat.interstitial:
        if (_loadingInterstitial) return;
        _loadingInterstitial = true;
        _interstitialReady = false;
        final ad = LevelPlayInterstitialAd(adUnitId: _units.interstitial);
        ad.setListener(_InterstitialListener(this));
        _interstitial = ad;
        await ad.loadAd();
      case AdFormat.rewarded:
        if (_loadingRewarded) return;
        _loadingRewarded = true;
        _rewardedReady = false;
        final ad = LevelPlayRewardedAd(adUnitId: _units.rewarded);
        ad.setListener(_RewardedListener(this));
        _rewarded = ad;
        await ad.loadAd();
    }
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null || !_interstitialReady) return false;
    if (await LevelPlayInterstitialAd.isPlacementCapped(
      interstitialPlacement,
    )) {
      return false;
    }
    if (!await ad.isAdReady()) {
      _interstitialReady = false;
      return false;
    }
    _interstitialReady = false;
    final closed = Completer<bool>();
    _interstitialClosed = closed;
    await ad.showAd(placementName: interstitialPlacement);
    return closed.future;
  }

  @override
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    final ad = _rewarded;
    if (ad == null || !_rewardedReady) return false;
    if (await LevelPlayRewardedAd.isPlacementCapped(rewardedPlacement)) {
      return false;
    }
    if (!await ad.isAdReady()) {
      _rewardedReady = false;
      return false;
    }
    _rewardedReady = false;
    _onReward = onReward;
    final closed = Completer<bool>();
    _rewardedClosed = closed;
    await ad.showAd(placementName: rewardedPlacement);
    return closed.future;
  }

  void _fail(AdFormat format, String reason) {
    _analytics.adFailed(
      format: format.name,
      provider: provider,
      reason: reason,
    );
  }
}

class _LevelPlayInitListener implements LevelPlayInitListener {
  _LevelPlayInitListener({required this.onSuccess, required this.onFailed});

  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) => onSuccess();

  @override
  void onInitFailed(LevelPlayInitError error) => onFailed();
}

class _InterstitialListener implements LevelPlayInterstitialAdListener {
  _InterstitialListener(this._service);

  final LevelPlayAdsService _service;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _service._loadingInterstitial = false;
    _service._interstitialReady = true;
    _service._analytics.adLoaded(
      format: AdFormat.interstitial.name,
      provider: _service.provider,
    );
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    _service._loadingInterstitial = false;
    _service._interstitialReady = false;
    _service._fail(AdFormat.interstitial, 'no_fill');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    _service._analytics.adShown(
      format: AdFormat.interstitial.name,
      provider: _service.provider,
      network: adInfo.adNetwork,
    );
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    _service._fail(AdFormat.interstitial, 'error');
    final closed = _service._interstitialClosed;
    if (closed != null && !closed.isCompleted) closed.complete(false);
    _service._interstitialClosed = null;
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    _service._analytics.adClicked(
      format: AdFormat.interstitial.name,
      provider: _service.provider,
    );
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    _service._analytics.adClosed(
      format: AdFormat.interstitial.name,
      provider: _service.provider,
    );
    final closed = _service._interstitialClosed;
    if (closed != null && !closed.isCompleted) closed.complete(true);
    _service._interstitialClosed = null;
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class _RewardedListener implements LevelPlayRewardedAdListener {
  _RewardedListener(this._service);

  final LevelPlayAdsService _service;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _service._loadingRewarded = false;
    _service._rewardedReady = true;
    _service._analytics.adLoaded(
      format: AdFormat.rewarded.name,
      provider: _service.provider,
    );
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    _service._loadingRewarded = false;
    _service._rewardedReady = false;
    _service._fail(AdFormat.rewarded, 'no_fill');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    _service._analytics.adShown(
      format: AdFormat.rewarded.name,
      provider: _service.provider,
      network: adInfo.adNetwork,
    );
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    _service._fail(AdFormat.rewarded, 'error');
    final closed = _service._rewardedClosed;
    if (closed != null && !closed.isCompleted) closed.complete(false);
    _service._rewardedClosed = null;
    _service._onReward = null;
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    _service._analytics.adClicked(
      format: AdFormat.rewarded.name,
      provider: _service.provider,
    );
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    _service._analytics.adClosed(
      format: AdFormat.rewarded.name,
      provider: _service.provider,
    );
    final closed = _service._rewardedClosed;
    if (closed != null && !closed.isCompleted) closed.complete(true);
    _service._rewardedClosed = null;
    _service._onReward = null;
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    _service._onReward?.call();
  }
}
