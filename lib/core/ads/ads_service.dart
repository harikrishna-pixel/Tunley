import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics.dart';
import '../analytics/events.dart';

enum AdFormat { interstitial, rewarded }

/// Every ad goes through this (`05` §12). Implementations never draw our UI
/// over a network ad and fail silently on no fill or offline.
abstract class AdsService {
  String get provider;

  /// Consent (UMP in the EEA/UK/CH, form only if required), then SDK start.
  /// Returns whether ads may be requested.
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

/// ironSource / Unity LevelPlay mediation (`06`, question #18). AdMob is the
/// default; this keeps the same contract until LevelPlay is chosen.
// TODO(question #18): implement with the LevelPlay Flutter plugin if picked.
class LevelPlayAdsService extends NoAdsService {
  const LevelPlayAdsService();

  @override
  String get provider => 'levelplay';
}
