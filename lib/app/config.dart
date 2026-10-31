import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Values from `docs/handoff/05_Business_Rules.md` §10 and §14.
class AppConfig {
  const AppConfig({
    required this.freeConversionsPerDay,
    required this.ringtoneMaxSeconds,
    required this.textToneDefaultSeconds,
    required this.fadeDefaultSeconds,
    required this.fadeMaxSeconds,
    required this.batchMaxFiles,
    required this.mergeMaxFiles,
    required this.volumeBoostMaxDb,
    required this.spaceMarginMb,
    required this.pendingKeepDays,
    required this.tempMaxAgeHours,
    required this.upsellCardEveryNthSuccess,
    required this.heavyUserFiles,
    required this.exitOfferMinutes,
    required this.winBackAfterDays,
    required this.winBackCooldownDays,
    required this.maxUnrequestedPaywallsPerSession,
    required this.rating,
    required this.milestones,
    required this.update,
    required this.ads,
    required this.moreApps,
    required this.houseCard,
    required this.referral,
    this.appStoreId,
    this.analyticsEuResidency = false,
  });

  final int freeConversionsPerDay;
  final int ringtoneMaxSeconds;
  final int textToneDefaultSeconds;
  final int fadeDefaultSeconds;
  final int fadeMaxSeconds;
  final int batchMaxFiles;
  final int mergeMaxFiles;
  final int volumeBoostMaxDb;
  final int spaceMarginMb;
  final int pendingKeepDays;
  final int tempMaxAgeHours;
  final int upsellCardEveryNthSuccess;
  final int heavyUserFiles;
  final int exitOfferMinutes;
  final int winBackAfterDays;
  final int winBackCooldownDays;
  final int maxUnrequestedPaywallsPerSession;
  final RatingConfig rating;
  final List<int> milestones;
  final UpdateConfig update;
  final AdsConfig ads;
  final List<MoreApp> moreApps;
  final HouseCardConfig houseCard;
  final ReferralConfig referral;

  /// Mixpanel data residency (`analytics.residency`: "us" or "eu").
  final bool analyticsEuResidency;

  /// Tunely's App Store id; null until the listing exists ("TBD").
  final String? appStoreId;

  /// App Store page (Update now, Copy link); null without an id.
  String? get appStoreUrl =>
      appStoreId == null ? null : 'https://apps.apple.com/app/id$appStoreId';

  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config/app_config.json');
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('app_config.json must be an object');
    }
    return AppConfig.fromJson(json);
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      freeConversionsPerDay: _int(json, 'freeConversionsPerDay'),
      ringtoneMaxSeconds: _int(json, 'ringtoneMaxSeconds'),
      textToneDefaultSeconds: _int(json, 'textToneDefaultSeconds'),
      fadeDefaultSeconds: _int(json, 'fadeDefaultSeconds'),
      fadeMaxSeconds: _int(json, 'fadeMaxSeconds'),
      batchMaxFiles: _int(json, 'batchMaxFiles'),
      mergeMaxFiles: _int(json, 'mergeMaxFiles'),
      volumeBoostMaxDb: _int(json, 'volumeBoostMaxDb'),
      spaceMarginMb: _int(json, 'spaceMarginMb'),
      pendingKeepDays: _int(json, 'pendingKeepDays'),
      tempMaxAgeHours: _int(json, 'tempMaxAgeHours'),
      upsellCardEveryNthSuccess: _int(json, 'upsellCardEveryNthSuccess'),
      heavyUserFiles: _int(json, 'heavyUserFiles'),
      exitOfferMinutes: _int(json, 'exitOfferMinutes'),
      winBackAfterDays: _int(json, 'winBackAfterDays'),
      winBackCooldownDays: _int(json, 'winBackCooldownDays'),
      maxUnrequestedPaywallsPerSession: _int(
        json,
        'maxUnrequestedPaywallsPerSession',
      ),
      rating: RatingConfig.fromJson(_map(json, 'rating')),
      milestones: _intList(json, 'milestones'),
      update: UpdateConfig.fromJson(_map(json, 'update')),
      ads: AdsConfig.fromJson(_map(json, 'ads')),
      moreApps: [
        for (final item in _list(json, 'moreApps'))
          MoreApp.fromJson(item as Map<String, dynamic>),
      ],
      houseCard: HouseCardConfig.fromJson(_map(json, 'houseCard')),
      referral: ReferralConfig.fromJson(_map(json, 'referral')),
      analyticsEuResidency:
          (json['analytics'] as Map<String, dynamic>?)?['residency'] == 'eu',
      appStoreId: switch (json['appStoreId']) {
        final String id when id.isNotEmpty && id != 'TBD' => id,
        _ => null,
      },
    );
  }
}

class RatingConfig {
  const RatingConfig({
    required this.afterRingtones,
    required this.afterConversions,
    required this.maxTimes,
    required this.minDaysBetween,
    required this.delayMs,
  });

  final int afterRingtones;
  final int afterConversions;
  final int maxTimes;
  final int minDaysBetween;
  final int delayMs;

  factory RatingConfig.fromJson(Map<String, dynamic> json) {
    return RatingConfig(
      afterRingtones: _int(json, 'afterRingtones'),
      afterConversions: _int(json, 'afterConversions'),
      maxTimes: _int(json, 'maxTimes'),
      minDaysBetween: _int(json, 'minDaysBetween'),
      delayMs: _int(json, 'delayMs'),
    );
  }
}

class UpdateConfig {
  const UpdateConfig({
    required this.latest,
    required this.minRecommended,
    this.notes = const [],
  });

  final String latest;
  final String minRecommended;

  /// Up to 3 "New in Tunely" bullets for the update sheet (29).
  final List<String> notes;

  factory UpdateConfig.fromJson(Map<String, dynamic> json) {
    return UpdateConfig(
      latest: _string(json, 'latest'),
      minRecommended: _string(json, 'minRecommended'),
      notes: [
        for (final note in json['notes'] as List<dynamic>? ?? const [])
          if (note is String) note,
      ].take(3).toList(),
    );
  }
}

class AdsConfig {
  const AdsConfig({
    required this.enabled,
    required this.provider,
    required this.firstSessionAds,
    required this.minConversionsBeforeFirstAd,
    required this.everyNthConversion,
    required this.minSecondsBetween,
    required this.maxPerDay,
    required this.rewardedMaxPerDay,
  });

  final bool enabled;
  final String provider;
  final bool firstSessionAds;
  final int minConversionsBeforeFirstAd;
  final int everyNthConversion;
  final int minSecondsBetween;
  final int maxPerDay;
  final int rewardedMaxPerDay;

  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    return AdsConfig(
      enabled: _bool(json, 'enabled'),
      provider: _string(json, 'provider'),
      firstSessionAds: _bool(json, 'firstSessionAds'),
      minConversionsBeforeFirstAd: _int(json, 'minConversionsBeforeFirstAd'),
      everyNthConversion: _int(json, 'everyNthConversion'),
      minSecondsBetween: _int(json, 'minSecondsBetween'),
      maxPerDay: _int(json, 'maxPerDay'),
      rewardedMaxPerDay: _int(json, 'rewardedMaxPerDay'),
    );
  }
}

class MoreApp {
  const MoreApp({
    required this.id,
    required this.name,
    required this.appStoreId,
    this.pitch,
    this.reason,
  });

  final String id;
  final String name;
  final String appStoreId;
  final String? pitch;

  /// Line under the "Picked for you" app on 45.
  final String? reason;

  /// False until the App Store listing exists ("TBD").
  bool get hasStoreId => appStoreId.isNotEmpty && appStoreId != 'TBD';

  factory MoreApp.fromJson(Map<String, dynamic> json) {
    return MoreApp(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      appStoreId: _string(json, 'appStoreId'),
      pitch: json['pitch'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class HouseCardConfig {
  const HouseCardConfig({
    required this.everyNthSuccess,
    required this.minDaysSinceInstall,
    required this.hideDays,
  });

  final int everyNthSuccess;
  final int minDaysSinceInstall;
  final int hideDays;

  factory HouseCardConfig.fromJson(Map<String, dynamic> json) {
    return HouseCardConfig(
      everyNthSuccess: _int(json, 'everyNthSuccess'),
      minDaysSinceInstall: _int(json, 'minDaysSinceInstall'),
      hideDays: _int(json, 'hideDays'),
    );
  }
}

class ReferralConfig {
  const ReferralConfig({
    required this.enabled,
    required this.friendDays,
    required this.inviterDays,
    required this.yearlyCap,
    this.appId = 'tunely',
    this.apiBaseUrl,
    this.inviteDomain = 'tunely.app',
  });

  final bool enabled;
  final int friendDays;
  final int inviterDays;
  final int yearlyCap;

  /// Sent with every auth and referral call (`12` §2).
  final String appId;

  /// Marberx auth/referral API; null until confirmed (debug uses a demo).
  final String? apiBaseUrl;
  final String inviteDomain;

  factory ReferralConfig.fromJson(Map<String, dynamic> json) {
    final base = json['apiBaseUrl'];
    return ReferralConfig(
      enabled: _bool(json, 'enabled'),
      friendDays: _int(json, 'friendDays'),
      inviterDays: _int(json, 'inviterDays'),
      yearlyCap: _int(json, 'yearlyCap'),
      appId: json['appId'] as String? ?? 'tunely',
      apiBaseUrl: base is String && base.isNotEmpty && base != 'TBD'
          ? base
          : null,
      inviteDomain: json['inviteDomain'] as String? ?? 'tunely.app',
    );
  }
}

/// Loaded in [main] and overridden before [runApp].
final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig must be loaded before runApp.');
});

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('app_config.$key must be an int');
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw FormatException('app_config.$key must be a bool');
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('app_config.$key must be a string');
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  throw FormatException('app_config.$key must be an object');
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value;
  }
  throw FormatException('app_config.$key must be a list');
}

List<int> _intList(Map<String, dynamic> json, String key) {
  return [
    for (final item in _list(json, key))
      if (item is int)
        item
      else
        throw FormatException('app_config.$key must be a list of ints'),
  ];
}
