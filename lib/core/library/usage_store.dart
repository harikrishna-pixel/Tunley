import 'dart:convert';

import '../entitlements/purchases.dart';
import '../rules/ad_policy.dart';
import '../rules/free_limit.dart';
import '../rules/house_card_policy.dart';
import 'app_database.dart';

/// Persisted counters behind the free limit, rating and milestones.
class UsageStore {
  UsageStore(this._db);

  final AppDatabase _db;

  static const _freeLimitKey = 'free_limit';
  static const _lifetimeKey = 'lifetime_conversions';
  static const _ringtonesKey = 'ringtones_saved';
  static const _folderKey = 'folder_bookmark';

  Future<FreeLimitSnapshot> readFreeLimit(DateTime now) async {
    final raw = await _db.readValue(_freeLimitKey);
    final today = FreeLimit.dayKeyFor(now);
    if (raw == null) {
      return FreeLimitSnapshot(
        usedToday: 0,
        rewardedToday: 0,
        dayKey: today,
        maxDayKey: today,
      );
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FreeLimitSnapshot(
      usedToday: json['usedToday'] as int,
      rewardedToday: json['rewardedToday'] as int,
      dayKey: json['dayKey'] as String,
      maxDayKey: json['maxDayKey'] as String,
    );
  }

  Future<void> writeFreeLimit(FreeLimitSnapshot snapshot) {
    return _db.writeValue(
      _freeLimitKey,
      jsonEncode({
        'usedToday': snapshot.usedToday,
        'rewardedToday': snapshot.rewardedToday,
        'dayKey': snapshot.dayKey,
        'maxDayKey': snapshot.maxDayKey,
      }),
    );
  }

  Future<int> lifetimeConversions() async =>
      int.tryParse(await _db.readValue(_lifetimeKey) ?? '') ?? 0;

  Future<int> ringtonesSaved() async =>
      int.tryParse(await _db.readValue(_ringtonesKey) ?? '') ?? 0;

  Future<void> recordSuccess({required bool ringtone}) async {
    await _db.writeValue(_lifetimeKey, '${await lifetimeConversions() + 1}');
    if (ringtone) {
      await _db.writeValue(_ringtonesKey, '${await ringtonesSaved() + 1}');
    }
  }

  Future<String?> folderBookmark() => _db.readValue(_folderKey);

  Future<void> setFolderBookmark(String id) => _db.writeValue(_folderKey, id);

  static const _ratingKey = 'rating_asked';
  static const _milestonesKey = 'milestones_shown';
  static const _updateKey = 'update_shown_version';
  static const _notifyKey = 'notify_prompts';

  Future<RatingMemory> rating() async {
    final raw = await _db.readValue(_ratingKey);
    if (raw == null) return const RatingMemory(times: 0);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return RatingMemory(
      times: json['times'] as int,
      lastAt: DateTime.tryParse(json['lastAt'] as String? ?? ''),
    );
  }

  Future<void> recordRatingAsked(DateTime at) async {
    final current = await rating();
    await _db.writeValue(
      _ratingKey,
      jsonEncode({'times': current.times + 1, 'lastAt': at.toIso8601String()}),
    );
  }

  Future<Set<String>> milestonesShown() async {
    final raw = await _db.readValue(_milestonesKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
  }

  Future<void> markMilestone(String key) async {
    final shown = await milestonesShown()
      ..add(key);
    await _db.writeValue(_milestonesKey, jsonEncode(shown.toList()));
  }

  Future<String?> updateShownVersion() => _db.readValue(_updateKey);

  Future<void> markUpdateShown(String version) =>
      _db.writeValue(_updateKey, version);

  /// Pre-prompt (27) contexts already used ("batch", "trial", "denied").
  Future<Set<String>> notifyPrompts() async {
    final raw = await _db.readValue(_notifyKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
  }

  Future<void> markNotifyPrompt(String key) async {
    final used = await notifyPrompts()
      ..add(key);
    await _db.writeValue(_notifyKey, jsonEncode(used.toList()));
  }
}

extension AdsUsage on UsageStore {
  static const _adsKey = 'ad_memory';
  static const _houseKey = 'house_card';
  static const _installKey = 'installed_at';
  static const _trackingKey = 'tracking_prompt_shown';

  Future<AdMemory> adMemory() async {
    final raw = await _db.readValue(_adsKey);
    if (raw == null) return const AdMemory();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return AdMemory(
      lastAdAt: DateTime.tryParse(j['lastAdAt'] as String? ?? ''),
      dayKey: j['dayKey'] as String?,
      adsToday: j['adsToday'] as int? ?? 0,
      conversionsSinceAd: j['conversionsSinceAd'] as int? ?? 0,
      rewardedDayKey: j['rewardedDayKey'] as String?,
      rewardedToday: j['rewardedToday'] as int? ?? 0,
    );
  }

  Future<void> writeAdMemory(AdMemory m) => _db.writeValue(
    _adsKey,
    jsonEncode({
      'lastAdAt': m.lastAdAt?.toIso8601String(),
      'dayKey': m.dayKey,
      'adsToday': m.adsToday,
      'conversionsSinceAd': m.conversionsSinceAd,
      'rewardedDayKey': m.rewardedDayKey,
      'rewardedToday': m.rewardedToday,
    }),
  );

  Future<HouseCardMemory> houseCard() async {
    final raw = await _db.readValue(_houseKey);
    if (raw == null) return const HouseCardMemory();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return HouseCardMemory(
      lastShownAt: DateTime.tryParse(j['lastShownAt'] as String? ?? ''),
      hiddenUntil: DateTime.tryParse(j['hiddenUntil'] as String? ?? ''),
      hideCount: j['hideCount'] as int? ?? 0,
    );
  }

  Future<void> writeHouseCard(HouseCardMemory m) => _db.writeValue(
    _houseKey,
    jsonEncode({
      'lastShownAt': m.lastShownAt?.toIso8601String(),
      'hiddenUntil': m.hiddenUntil?.toIso8601String(),
      'hideCount': m.hideCount,
    }),
  );

  /// First launch time, recorded on first read.
  Future<DateTime> installedAt([DateTime? now]) async {
    final stored = DateTime.tryParse(await _db.readValue(_installKey) ?? '');
    if (stored != null) return stored;
    final at = now ?? DateTime.now();
    await _db.writeValue(_installKey, at.toIso8601String());
    return at;
  }

  /// Last plan bought on this device; win-back shares the yearly product.
  Future<PlanKind?> lastPlanKind() async {
    final raw = await _db.readValue('last_plan_kind');
    return PlanKind.values.where((k) => k.name == raw).firstOrNull;
  }

  Future<void> setLastPlanKind(PlanKind kind) =>
      _db.writeValue('last_plan_kind', kind.name);

  /// Ads & tracking pre-prompt (44), once ever.
  Future<bool> trackingPromptShown() async =>
      await _db.readValue(_trackingKey) == '1';

  Future<void> markTrackingPromptShown() => _db.writeValue(_trackingKey, '1');
}

class RatingMemory {
  const RatingMemory({required this.times, this.lastAt});

  final int times;
  final DateTime? lastAt;
}
